#include "ufs_mpas.h"

! -- test

module ufs_mpas_types

  use ESMF
  use mpas_derived_types, only : core_type, domain_type

  implicit none

  type ufs_mpas_internal_data_type
    type (core_type),   pointer :: corelist => null()
    type (domain_type), pointer :: domain   => null()
  end type ufs_mpas_internal_data_type

  type ufs_geom_internal_data_type
    type (ESMF_Grid) :: grid
    type (ESMF_Mesh) :: mesh
  end type ufs_geom_internal_data_type

  type ufs_internal_data_type
    type (ufs_geom_internal_data_type) :: geom
    type (ufs_mpas_internal_data_type) :: mpas
  end type ufs_internal_data_type

  type ufs_internal_state_type
    type (ufs_internal_data_type), pointer :: wrap => null()
  end type ufs_internal_state_type

  private

  public :: ufs_internal_data_type
  public :: ufs_mpas_internal_state_initialize
  public :: ufs_mpas_internal_state_finalize
  public :: ufs_mpas_internal_data_get

contains

  function ufs_mpas_internal_data_get(model, rc) result (data)

    type(ESMF_GridComp)            :: model
    integer, optional, intent(out) :: rc

    type(ufs_internal_data_type), pointer :: data

    ! -- local variables
    _rc_var_define_
    type(ufs_internal_state_type) :: is

    ! -- begin
    _rc_init_
    nullify(data)

    call ESMF_GridCompGetInternalState(model, is, _rc_)

    data => is % wrap

  end function ufs_mpas_internal_data_get

  subroutine ufs_mpas_internal_state_initialize(model, rc)

    type(ESMF_GridComp)            :: model
    integer, optional, intent(out) :: rc

    ! -- local variables
    _rc_var_define_
    _stat_var_define_
    type(ufs_internal_state_type) :: is

    ! -- begin
    _rc_init_

    allocate(is % wrap, _alloc_stat_)

    call ESMF_GridCompSetInternalState(model, is, _rc_)

  end subroutine ufs_mpas_internal_state_initialize

  subroutine ufs_mpas_internal_state_finalize(model, rc)

    type(ESMF_GridComp)            :: model
    integer, optional, intent(out) :: rc

    ! -- local variables
    _rc_var_define_
    _stat_var_define_
    type(ufs_internal_state_type) :: is

    ! -- begin
    _rc_init_
    call ESMF_GridCompGetInternalState(model, is, _rc_)

    if (associated(is % wrap)) then
      deallocate(is % wrap, _deall_stat_)
      nullify(is % wrap)
    end if

  end subroutine ufs_mpas_internal_state_finalize

end module ufs_mpas_types
