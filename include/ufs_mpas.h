#ifndef _ufs_mpas_h
#define _ufs_mpas_h	1

#define _ufs_log_err_				ESMF_RC_INTNRL_BAD
#define _ufs_log_msg_				ESMF_LOGERR_PASSTHRU
#define _ufs_log_check_				ESMF_LogFoundError
#define _ufs_log_set_				ESMF_LogSetError
#define _ufs_log_args_(a,b,m)			rcToCheck=a, msg=m, file=__FILE__, line=__LINE__, rcToReturn=b

#define _ufs_assert_set_(c,a,b,m)		\
	if (.not.(c)) then; \
		call _ufd_log_set_(_ufs_log_args(a,b,m)); \
		return; \
	end if
#define _ufs_assert_(c)				_ufs_assert_set_(c,_ufs_log_err_,rc,_ufs_log_msg_)

#define _rc_var_define_				integer :: localrc
#define _rc_arg_define_				integer, optional, intent(out) :: rc
#define _rc_set_ok_				rc = ESMF_SUCCESS
#define _rc_init_				if (present(rc)) _rc_set_ok
#define _rc_check_(a,b,m)			\
	if (_ufs_log_check_(_ufs_log_args_(a,b,m))) return
#define _rc_					rc=localrc) ; _rc_check_(localrc,rc,_ufs_log_msg_

#endif
