#include "ufs_mpas.h"

module ufs_mpas_methods

  use ESMF
  use NUOPC

  use mpas_subdriver
  use mpas_derived_types, only : core_type, domain_type

  use ufs_mpas_types

  implicit none

  private

  public :: ufs_mpas_model_initialize
  public :: ufs_mpas_model_run
  public :: ufs_mpas_model_finalize

contains

  subroutine ufs_mpas_model_initialize(model, rc)

    type(ESMF_GridComp)            :: model
    integer, optional, intent(out) :: rc

    ! -- local variables
    _rc_var_define_
    _stat_var_define_
    integer        :: comm
    type (ESMF_VM) :: vm
    type (ufs_mpas_internal_state_type) :: is

    ! -- begin
    _rc_init_

    ! -- allocate component's private data structure storing MPAS info
    allocate(is % mpas, _alloc_stat_)

    ! -- retrieve MPI communicator from component's VM 
    call ESMF_GridCompGet(model, vm=vm, _rc_)
    call ESMF_VMGet(vm, mpiCommunicator=comm)

    ! -- initialize MPAS
    call mpas_init(is % mpas % corelist, is % mpas % domain, external_comm=comm)

    ! -- add internal state to component
    call ESMF_GridCompSetInternalState(model, is, _rc_)

  end subroutine ufs_mpas_model_initialize


  subroutine ufs_mpas_model_run(model, rc)

    type(ESMF_GridComp)            :: model
    integer, optional, intent(out) :: rc

    ! -- local variables
    _rc_var_define_
    integer           :: comm
    type(core_type)   :: corelist
    type(domain_type) :: domain
    type(ESMF_VM)     :: vm
    type(ufs_mpas_internal_state_type) :: is

    ! -- begin
    _rc_init_

    ! -- retrieve component's internal state
    call ESMF_GridCompGetInternalState(model, is, _rc_)

    ! -- run MPAS
    if (associated(is % mpas)) call mpas_run(is % mpas % domain)

  end subroutine ufs_mpas_model_run

  subroutine ufs_mpas_model_finalize(model, rc)

    type(ESMF_GridComp)            :: model
    integer, optional, intent(out) :: rc

    ! -- local variables
    _rc_var_define_
    _stat_var_define_
    type(ufs_mpas_internal_state_type) :: is

    ! -- retrieve component's internal state
    call ESMF_GridCompGetInternalState(model, is, _rc_)

    ! -- finalize MPAS
    if (associated(is % mpas)) then
      call mpas_finalize(is % mpas % corelist, is % mpas % domain)
      deallocate(is % mpas, _deall_stat_)
    end if

  end subroutine ufs_mpas_model_finalize

end module ufs_mpas_methods
