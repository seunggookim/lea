function [ind,foundstr] = myfs_findannot(surfs, roiname, verbose)
% [ind,foundstr] = myfs_findannot(surfs, roiname, verbose)
%
% INPUTS
% surfs     [1x1] FS surface structure from FSSS_READ_ALL_FS_SURFS
% roiname   {1xN} keywords or names as in annot.cot.struct_names
% verbose   [1x1] true (default)
%
% aparc_a2009s 76 labels:
%     {'Unknown'                  }
%     {'G_and_S_frontomargin'     }
%     {'G_and_S_occipital_inf'    }
%     {'G_and_S_paracentral'      }
%     {'G_and_S_subcentral'       }
%     {'G_and_S_transv_frontopol' }
%     {'G_and_S_cingul-Ant'       }
%     {'G_and_S_cingul-Mid-Ant'   }
%     {'G_and_S_cingul-Mid-Post'  }
%     {'G_cingul-Post-dorsal'     }
%     {'G_cingul-Post-ventral'    }
%     {'G_cuneus'                 }
%     {'G_front_inf-Opercular'    }
%     {'G_front_inf-Orbital'      }
%     {'G_front_inf-Triangul'     }
%     {'G_front_middle'           }
%     {'G_front_sup'              }
%     {'G_Ins_lg_and_S_cent_ins'  }
%     {'G_insular_short'          }
%     {'G_occipital_middle'       }
%     {'G_occipital_sup'          }
%     {'G_oc-temp_lat-fusifor'    }
%     {'G_oc-temp_med-Lingual'    }
%     {'G_oc-temp_med-Parahip'    }
%     {'G_orbital'                }
%     {'G_pariet_inf-Angular'     }
%     {'G_pariet_inf-Supramar'    }
%     {'G_parietal_sup'           }
%     {'G_postcentral'            }
%     {'G_precentral'             }
%     {'G_precuneus'              }
%     {'G_rectus'                 }
%     {'G_subcallosal'            }
%     {'G_temp_sup-G_T_transv'    }
%     {'G_temp_sup-Lateral'       }
%     {'G_temp_sup-Plan_polar'    }
%     {'G_temp_sup-Plan_tempo'    }
%     {'G_temporal_inf'           }
%     {'G_temporal_middle'        }
%     {'Lat_Fis-ant-Horizont'     }
%     {'Lat_Fis-ant-Vertical'     }
%     {'Lat_Fis-post'             }
%     {'Medial_wall'              }
%     {'Pole_occipital'           }
%     {'Pole_temporal'            }
%     {'S_calcarine'              }
%     {'S_central'                }
%     {'S_cingul-Marginalis'      }
%     {'S_circular_insula_ant'    }
%     {'S_circular_insula_inf'    }
%     {'S_circular_insula_sup'    }
%     {'S_collat_transv_ant'      }
%     {'S_collat_transv_post'     }
%     {'S_front_inf'              }
%     {'S_front_middle'           }
%     {'S_front_sup'              }
%     {'S_interm_prim-Jensen'     }
%     {'S_intrapariet_and_P_trans'}
%     {'S_oc_middle_and_Lunatus'  }
%     {'S_oc_sup_and_transversal' }
%     {'S_occipital_ant'          }
%     {'S_oc-temp_lat'            }
%     {'S_oc-temp_med_and_Lingual'}
%     {'S_orbital_lateral'        }
%     {'S_orbital_med-olfact'     }
%     {'S_orbital-H_Shaped'       }
%     {'S_parieto_occipital'      }
%     {'S_pericallosal'           }
%     {'S_postcentral'            }
%     {'S_precentral-inf-part'    }
%     {'S_precentral-sup-part'    }
%     {'S_suborbital'             }
%     {'S_subparietal'            }
%     {'S_temporal_inf'           }
%     {'S_temporal_sup'           }
%     {'S_temporal_transverse'    }
%
% SEE ALSO: MYFS_READSURFS
% (cc) 2019, sgKIM. solleo@gmail.com
if ~nargin, help(mfilename); return; end
if ~exist('verbose','var')
  verbose = true;
end
annot = surfs.aparc; % simplified.
% disp(annot.aparcname);
side = {'lh','rh'};
for ihemi = 1:2
  ind_str = contains(annot{ihemi}.cot.struct_names, roiname);
  label_trg = annot{ihemi}.cot.table(ind_str,5);
  ind{ihemi} = ismember(annot{ihemi}.label, label_trg');
  foundstr = annot{ihemi}.cot.struct_names(ind_str);
  if verbose
    fprintf('[%s] found %i labels, #verts=%i:\n', ...
      side{ihemi}, numel(foundstr), sum(ind{ihemi}));
    disp(foundstr)
  end
end

end