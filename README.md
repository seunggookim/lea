# LEA👧 - Linearized Encoding Analysis

<img src="private/img/lea-overview.png">

This MATLAB package is to perform linearized encoding analysis on time series data (see [Kim, 2022, Frontiers in Neuroscience](https://doi.org/10.3389/fnins.2022.928841)).

This version (v0.0.0-alpha-20240902) is for a tutorial at KSMPC (Korean Society for Music Perception and Cognition) Summer School 2024 [[only Korean]](https://www.ksmpc.kr/single-post/2024-%EC%A0%9C-3-%ED%9A%8C-%ED%95%9C%EA%B5%AD%EC%9D%8C%EC%95%85%EC%A7%80%EA%B0%81%EC%9D%B8%EC%A7%80%ED%95%99%ED%9A%8C-%EC%97%AC%EB%A6%84%ED%95%99%EA%B5%90). Currently, only nested leave-one-stimulus-out cross-validation is implemented. Each response unit is optimized separately via grid search, but a single lambda regularizes all stimulus features.

Please see `/README.mlx` on MATLAB to learn more about it.

If you don't have access to a MATLAB license, please know that you can still use MATLAB Online Basic for an educational purpose (free 30 hours/month) at [matlab.mathworks.com](https://matlab.mathworks.com).

For the methodological background of the analysis, please see [the tutorial (mostly English)](https://github.com/seunggookim/ksmpc-ss24-sess3).

(CC0-BY) 2024-09-02, [seung-goo.kim@ae.mpg.de](mailto:seung-goo.kim@ae.mpg.de)

