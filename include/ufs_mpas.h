#ifndef _ufs_mpas_h
#define _ufs_mpas_h	1

#define _rc_var_define_				integer :: localrc
#define _rc_arg_define_				integer, optional, intent(out) :: rc
#define _rc_init_				if (present(rc)) rc = ESMF_SUCCESS
#define _rc_check_(errinp, errout, errmsg)	\
	if (ESMF_LogFoundError(rcToCheck=errinp, msg=errmsg, \
		file=__FILE__, line=__LINE__, \
		rcToReturn=errout)) return
#define _rc_					rc=localrc) ; _rc_check_(localrc, rc, ESMF_LOGERR_PASSTHRU

#endif
