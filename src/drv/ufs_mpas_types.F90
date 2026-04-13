module ufs_mpas_types

  use ESMF
  use mpas_derived_types, only : core_type, domain_type

  implicit none

  type ufs_mpas_internal_data_type
    type (core_type),   pointer :: corelist => null()
    type (domain_type), pointer :: domain   => null()
  end type ufs_mpas_internal_data_type

  type ufs_mpas_internal_state_type
    type (ufs_mpas_internal_data_type), pointer :: mpas => null()
  end type ufs_mpas_internal_state_type

  private

  public :: ufs_mpas_internal_data_type
  public :: ufs_mpas_internal_state_type

end module ufs_mpas_types
