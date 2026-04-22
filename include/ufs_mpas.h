#ifndef _ufs_mpas_h
#define _ufs_mpas_h	1

#define _ufs_log_err_				ESMF_RC_INTNRL_BAD
#define _ufs_log_msg_				ESMF_LOGERR_PASSTHRU
#define _ufs_log_check_				ESMF_LogFoundError
#define _ufs_log_alloc_check_			ESMF_LogFoundAllocError
#define _ufs_log_deall_check_			ESMF_LogFoundDeallocError
#define _ufs_log_set_				ESMF_LogSetError
#define _ufs_log_args_(a,b,m)			rcToCheck=a, msg=m, file=__FILE__, line=__LINE__, rcToReturn=b
#define _ufs_log_stat_args_(a,b,m)		statusToCheck=a, msg=m, file=__FILE__, line=__LINE__, rcToReturn=b

#define _ufs_assert_set_(c,a,b,m)		\
	if (.not.(c)) then; \
		call _ufs_log_set_(_ufs_log_args_(a,b,m)); \
		return; \
	end if
#define _ufs_assert_log_(c,e,m)			_ufs_assert_set_(c,e,rc,m)
#define _ufs_assert_(c)				_ufs_assert_log_(c,_ufs_log_err_,_ufs_log_msg_)

#define _rc_var_define_				integer :: localrc
#define _rc_arg_define_				integer, optional, intent(out) :: rc
#define _rc_set_ok_				rc = ESMF_SUCCESS
#define _rc_init_				if (present(rc)) _rc_set_ok_
#define _rc_check_(a,b,m)			\
	if (_ufs_log_check_(_ufs_log_args_(a,b,m))) return
#define _rc_					rc=localrc) ; _rc_check_(localrc,rc,_ufs_log_msg_

#define _stat_var_define_			integer :: stat
#define _stat_check_(func,a,b,m)			\
	if (func(_ufs_log_stat_args_(a,b,m))) return
#define _alloc_stat_				stat=stat) ; _stat_check_(_ufs_log_alloc_check_,stat,rc,_ufs_log_msg_
#define _deall_stat_				stat=stat) ; _stat_check_(_ufs_log_deall_check_,stat,rc,_ufs_log_msg_

#endif
