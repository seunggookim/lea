classdef Ts < timeseries
  %TS is a custom subclass of MATLAB's TIMESERIES class
  %
  % <a href="matlab:help Ts">TS</a>: create an instance
  % >> Ts = ts(dataMatrix, timeVector)
  %
  % <a href="matlab:help ts/save">SAVE</a>: save in a .TS/.HD pair
  % >> save(Ts, 'example.ts')
  %
  % <a href="matlab:help ts/load">LOAD</a>: load from a .TS/.HD pair
  % >> Ts = ts.load('example.ts')
  %
  % <a href="matlab:help ts/view">VIEW</a>: view data [fmri/eeg/bhv/stim]
  % >> view(Ts)
  %
  % <a href="matlab:help ts/detrendts">DETRENDTS</a>: detrend it while keeping meta data
  % >> DetrendedTs = detrendts(Ts, 'linear')
  %
  % <a href="matlab:help ts/zscore">ZSCORE</a>: zscore it while keeping meta data
  % >> ZscoredTs = zscore(Ts, true)
  %
  % <a href="matlab:help ts/mean">MEAN</a>: mean TS objects while keeping meta data
  % >> MeanTs= mean([Ts1, Ts2, ..., TsN])
  %
  % (CC4-BY) 2024, seung-goo.kim@ae.mpg.de
  %
  % Type <a href="matlab:methods(ts)">methods(ts)</a> to see all class methods
  % See also TIMESERIES

  % <a href="matlab:help ts/test">TEST</a>: run unit tests
  % >> ts.test()

  properties
  end % of properties

  % FIND DYNAMIC METHODS IN THE @TS FODLER! :D

  methods(Static)

    function ts = load(fnameTs)
      %TS.LOAD loads a TS object from a .TS/.HD pair
      %   ts = TS.load(FILENAME)
      %   FILENAME is a character vector or a string scalar as 'example.ts' or "example.ts"
      %   TSTOSAVE is a loaded TS object.
      %
      %Example:
      %ts = Ts.load('example.ts')

      fnameTs = char(fnameTs);
      assert( contains(fnameTs, '.ts'), 'Input filename "%s" does not look like a TS file!', fnameTs)
      assert( isfile(fnameTs), 'File "%s" not found!', fnameTs)

      load(strrep(fnameTs, '.ts', '.hd'), '-MAT', 'ts');
      origTimeInfo = ts.UserData.OrigTimeInfo;
      origDataInfo = ts.UserData.OrigDataInfo;
      fid = fopen(fnameTs, 'r');
      ts = addsample(ts, 'Time', (origTimeInfo.Start : origTimeInfo.Increment : origTimeInfo.End)', ...
        'Data', fread(fid, origDataInfo.UserData.MatrixDimension, origDataInfo.UserData.Precision));
      fclose(fid);
      ts = setuniformtime(ts, 'Interval', origTimeInfo.Increment);
    end


    %%
    function test(todo)
      %TS.TEST runs a batch of unit tests
      %
      %Example:
      %Ts.test()                 % runs all batches
      %Ts.test("io")             % runs the 'io' batch
      %Ts.test(["io","std"])     % runs the 'io' batch and 'std' batch
      if not(nargin)
        todo = ["io", "std"];
      end

      if contains("io", todo)
        writeandreadthis('int8',  [5*1000 10*1000])
        writeandreadthis('double', [1000 100*1000])
        writeandreadthis('single', [500 100*1000])
        writeandreadthis('int32',  [500 100*1000])
      end

      if contains("std", todo)
        detrendandzscorethis('double',  [100 100*1000])
        detrendandzscorethis('single',  [10*1000 32])
      end

      function writeandreadthis(precision, dimensions)
        a = Ts(randi(255, dimensions, precision), 'Name','eeg');
        a.DataInfo.Units = 'uV';
        fname = [tempname,'.ts'];
        tic; save(a, fname); fprintf('saving a TS [%s: %i x %i]: ', upper(precision), dimensions);
        fprintf('TOOK %s\n', duration(seconds(toc), Format='mm:ss.SSS'))
        s = dir(fname);
        fprintf('> DATA FILE SIZE = %s\n', formatbytes(s.bytes))
        s = dir(strrep(fname, '.ts', '.hd'));
        fprintf('> HEADER FILE SIZE = %s\n', formatbytes(s.bytes))
        tic; b = Ts.load(fname); fprintf('loading a TS [%s: %i x %i]: ', upper(precision), dimensions);
        fprintf('TOOK %s\n', duration(seconds(toc), Format='mm:ss.SSS'))
        assert(isequal(a.Data ,b.Data))
        assert(isequal(a.Time ,b.Time))
        assert(isequal(a.TimeInfo ,b.TimeInfo))
        assert(isequal(a.DataInfo.Units, b.DataInfo.Units))
        fprintf('[PASS]: saved and loaded matched!\n\n')
      end

      function detrendandzscorethis(precision, dimensions)
        switch precision
          case 'double'
            TOL = 1e-16;
          case 'single'
            TOL = 1e-7;
          otherwise
            error('precision="%s" not allowed for too large errors! Use SINGLE or DOUBLE')
        end
        a = Ts(rand(dimensions, precision), 'Name','fmri');
        a.DataInfo.Units = 'au';
        fprintf('created a random TS [%s: %i x %i]\n',precision, dimensions)

        tic; fprintf('no detrending..')
        b0 = detrend(a, 'none');
        fprintf('TOOK %s\n', duration(seconds(toc), Format='mm:ss.SSS'))
        assert(isequal(a.Data, b0.Data))
        assert(isequal(b0.DataInfo.UserData.Detrend.Method, 'none'))

        tic; fprintf('0-th order detrending..')
        b1 = detrend(a, 'constant');
        fprintf('TOOK %s\n', duration(seconds(toc), Format='mm:ss.SSS'))
        assert(all(mean(a) == b1.DataInfo.UserData.Detrend.OrigMean))
        c = b1.Data + b1.DataInfo.UserData.Detrend.OrigMean;
        err = rms(a.Data(:) - c(:));
        fprintf('Detrending recover error RMS = %.4i\n', err)
        assert(err < TOL)

        tic; fprintf('1-st order detrending..')
        b2 = detrend(a, 'linear');
        fprintf('TOOK %s\n', duration(seconds(toc), Format='mm:ss.SSS'))

        t = (1:size(a.Data,1))';
        t = t - mean(t);
        c = b2.Data + b2.DataInfo.UserData.Detrend.OrigMean + t*b2.DataInfo.UserData.Detrend.OrigSlope;
        err = rms(a.Data(:) - c(:));
        fprintf('Detrending recover error RMS = %.4i\n', err)
        assert(err < TOL)

        tic; fprintf('Z-scoring..')
        z = zscore(a, 1);
        fprintf('TOOK %s\n', duration(seconds(toc), Format='mm:ss.SSS'))
        assert(all(mean(a) == z.DataInfo.UserData.Zscore.OrigMean))
        c = z.Data .* z.DataInfo.UserData.Zscore.OrigStd + z.DataInfo.UserData.Zscore.OrigMean;
        err = rms(a.Data(:) - c(:));
        fprintf('Z-score recover error RMS = %.4i\n', err)
        assert(err < TOL)

        fprintf('[PASS]: detrending and z-scoring with tolerable erorrs.\n\n')
      end
    end


    %%
    function ts = Ts(varargin)
      %TS() calls the timeseries constructor
      ts@timeseries(varargin{:})
    end

  end % of static methods

end % of class
