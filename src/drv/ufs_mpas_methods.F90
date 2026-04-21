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
    integer                                :: comm
    type (ESMF_VM)                         :: vm
    type (ufs_internal_data_type), pointer :: data => null()

    type(ESMF_Mesh) :: mesh ! TEST

    ! -- begin
    _rc_init_

    ! -- retrieve component's private data container
    data => ufs_mpas_internal_data_get(model, _rc_)

    if (associated(data)) then
      ! -- retrieve MPI communicator from component's VM
      call ESMF_GridCompGet(model, vm=vm, _rc_)
      call ESMF_VMGet(vm, mpiCommunicator=comm)

      ! -- initialize MPAS
      call mpas_init(data % mpas % corelist, data % mpas % domain, external_comm=comm)
    end if

  end subroutine ufs_mpas_model_initialize


  subroutine ufs_mpas_model_run(model, rc)

    type(ESMF_GridComp)            :: model
    integer, optional, intent(out) :: rc

    ! -- local variables
    _rc_var_define_
    integer                               :: comm
    type(core_type)                       :: corelist
    type(domain_type)                     :: domain
    type(ufs_internal_data_type), pointer :: data => null()

    ! -- begin
    _rc_init_

    ! -- retrieve component's private data container
    data => ufs_mpas_internal_data_get(model, _rc_)

    ! -- run MPAS
    if (associated(data)) call mpas_run(data % mpas % domain)

  end subroutine ufs_mpas_model_run


  subroutine ufs_mpas_model_finalize(model, rc)

    type(ESMF_GridComp)            :: model
    integer, optional, intent(out) :: rc

    ! -- local variables
    _rc_var_define_
    type(ufs_internal_data_type), pointer :: data => null()

    ! -- retrieve component's private data container
    data => ufs_mpas_internal_data_get(model, _rc_)

    ! -- finalize MPAS
    if (associated(data)) then
      call mpas_finalize(data % mpas % corelist, data % mpas % domain)
    end if

  end subroutine ufs_mpas_model_finalize

end module ufs_mpas_methods
