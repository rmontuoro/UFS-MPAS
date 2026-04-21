#include "ufs_mpas.h"

module ufs_mpas_cap

  use ESMF
  use NUOPC
  use NUOPC_Model, &
    ModelSS => SetServices

  use ufs_mpas_geom
  use ufs_mpas_methods
  use ufs_mpas_types

  implicit none

  private

  public :: SetServices,    &
            DataInitialize, &
            Advance,        &
            Finalize

contains

  subroutine SetServices(model, rc)

    type(ESMF_GridComp)  :: model
    integer, intent(out) :: rc

    ! -- local variables
    _rc_var_define_

    ! -- begin
    _rc_set_ok_

    ! -- derive component from generic NUOPC_Model
    call NUOPC_CompDerive(model, modelSS, _rc_)

    ! -- specialize generic Model component
    call NUOPC_CompSpecialize(model, specLabel=label_DataInitialize, &
      specRoutine=DataInitialize, _rc_)

    call NUOPC_CompSpecialize(model, specLabel=label_Advance, &
      specRoutine=Advance, _rc_)

    call NUOPC_CompSpecialize(model, specLabel=label_Finalize, &
      specRoutine=Finalize, _rc_)

  end subroutine SetServices


  subroutine DataInitialize(model, rc)

    type(ESMF_GridComp)  :: model
    integer, intent(out) :: rc

    ! -- local variables
    _rc_var_define_
    integer                    :: localPet, petCount
    character(len=ESMF_MAXSTR) :: logm
    type(ESMF_VM)              :: vm

    ! -- begin
    _rc_set_ok_

    call ESMF_GridCompGet(model, vm=vm, _rc_)
    call ESMF_VMGet(vm, localPet=localPet, petCount=petCount, _rc_)
    write(logm, '("UFS-ATM: DataInitialize: PET: ",i0," of ",i0)') localPet, petCount
    call ESMF_LogWrite(logm, _rc_)

    ! -- initialize component's internal state
    call ufs_mpas_internal_state_initialize(model, _rc_)

    ! -- initialize MPAS model
    call ufs_mpas_model_initialize(model, _rc_)

    ! -- create component's geometry objects
    call ufs_mpas_geom_initialize(model, _rc_)

    ! -- NUOPC DataInitialize phase is now complete
    call NUOPC_CompAttributeSet(model, name="InitializeDataComplete", value="true", _rc_)
    
  end subroutine DataInitialize


  subroutine Advance(model, rc)

    type(ESMF_GridComp)  :: model
    integer, intent(out) :: rc

    ! -- local variables
    _rc_var_define_
    integer                    :: i, n
    character(len=ESMF_MAXSTR) :: clockStr, clockOptions(3), name
    type(ESMF_Clock)           :: driverClock, modelClock, clock
    type(ESMF_TimeInterval)    :: timeStep

    ! -- begin
    _rc_set_ok_

    call ESMF_LogWrite("UFS-ATM: Advance", _rc_)

    ! -- retrieve clock
    call NUOPC_ModelGet(model, driverClock=driverClock, modelClock=modelClock, _rc_)

    ! -- print clock properties
    clockOptions = [ "startTime", "stopTime", "currTime" ]

    clock = driverClock
    name  = "driver"
    do n = 1, 2
      do i = 1, size(clockOptions)
        call ESMF_ClockPrint(clock, options=clockOptions(i), unit=clockStr, _rc_)
        call ESMF_LogWrite("UFS-ATM: Advance: "//trim(name)//": "//trim(clockOptions(i))//": " // clockStr, _rc_)
      end do
      call ESMF_ClockGet(clock, timeStep=timeStep, _rc_)
      call ESMF_TimeIntervalGet(timeStep, timeString=clockStr, _rc_)
      call ESMF_LogWrite("UFS-ATM: Advance: "//trim(name)//": timeStep: " // clockStr, _rc_)
      clock = modelClock
      name  = "model"
    end do

    ! -- call MPAS run method
    call ufs_mpas_model_run(model, _rc_)
    
  end subroutine Advance


  subroutine Finalize(model, rc)

    type(ESMF_GridComp)  :: model
    integer, intent(out) :: rc

    ! -- local variables
    _rc_var_define_

    ! -- begin
    _rc_set_ok_

    call ESMF_LogWrite("UFS-ATM: Finalize", _rc_)

    ! -- finalize MPAS model
    call ufs_mpas_model_finalize(model, _rc_)

    ! -- free up memory from geometry objects
    call ufs_mpas_geom_finalize(model, _rc_)

    ! -- free up memory from internal state
    call ufs_mpas_internal_state_finalize(model, _rc_)

  end subroutine Finalize
  
end module ufs_mpas_cap
