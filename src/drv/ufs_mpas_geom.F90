#include "ufs_mpas.h"

module ufs_mpas_geom

  use ESMF
  use mpas_framework
  use ufs_mpas_types

  implicit none

  private

  public :: ufs_mpas_geom_initialize, &
            ufs_mpas_geom_finalize

contains

  subroutine ufs_mpas_geom_initialize(model, rc)

    type(ESMF_GridComp)            :: model
    integer, optional, intent(out) :: rc

    ! -- local variables
    _rc_var_define_
    _stat_var_define_
    integer(ESMF_KIND_I4), dimension(2)   :: output_grid_size
    logical                               :: isPresent
    type(ESMF_Config)                     :: cf
    type(ESMF_VM)                         :: vm
    type(ufs_internal_data_type), pointer :: data

    ! -- local parameters
    character(len=*), parameter :: configFileName = "model_configure"
    character(len=*), parameter :: configLabel    = "output_grid_size:"

    ! -- begin
    _rc_init_

    ! -- get component's internal state
    data => ufs_mpas_internal_data_get(model, _rc_)

    if (associated(data)) then

      ! -- create UFS mesh

      call ESMF_GridCompGet(model, vm=vm, _rc_)
      data % geom % mesh = ufs_mpas_mesh_create(vm, data % mpas % domain, _rc_)

      ! -- create output grid, if requested
      cf = ESMF_ConfigCreate(_rc_)
      call ESMF_ConfigLoadFile (cf, configFileName, _rc_)
      call ESMF_ConfigFindLabel(cf, configLabel, isPresent=isPresent, _rc_)

      if (isPresent) then
        call ESMF_ConfigGetAttribute(cf, output_grid_size, label=configLabel, _rc_)
        data % geom % grid = ufs_mpas_grid_create(output_grid_size, _rc_)
      end if

      call ESMF_ConfigDestroy(cf, _rc_)
    end if
    
  end subroutine ufs_mpas_geom_initialize


  subroutine ufs_mpas_geom_finalize(model, rc)

    type(ESMF_GridComp)            :: model
    integer, optional, intent(out) :: rc

    ! -- local variables
    _rc_var_define_
    _stat_var_define_
    logical                                :: isCreated
    type (ufs_internal_data_type), pointer :: data

    ! -- begin
    _rc_init_

    ! -- get component's internal state
    data => ufs_mpas_internal_data_get(model, _rc_)

    if (associated(data)) then

      isCreated = ESMF_MeshIsCreated(data % geom % mesh, _rc_)
      if (isCreated) then
        call ESMF_MeshDestroy(data % geom % mesh, _rc_)
      end if

      isCreated = ESMF_GridIsCreated(data % geom % grid, _rc_)
      if (isCreated) then
        call ESMF_GridDestroy(data % geom % grid, _rc_)
      end if

    end if
    
  end subroutine ufs_mpas_geom_finalize


  function ufs_mpas_grid_create(grid_size, rc) result (grid)

    integer, dimension(:), intent(in)  :: grid_size
    integer, optional,     intent(out) :: rc

    type(ESMF_Grid) :: grid
 
    ! -- local variables
    _rc_var_define_
    integer                                   :: item, i, j
    integer,            dimension(1)          :: lb, ub
    real(ESMF_KIND_R8)                        :: dx
    real(ESMF_KIND_R8), dimension(:), pointer :: xp

    ! -- local parameters
    real(ESMF_KIND_R8), parameter :: grid_domain(2,2) = &
                                       [ -180._ESMF_KIND_R8, -90._ESMF_KIND_R8,  &
                                          360._ESMF_KIND_R8, 180._ESMF_KIND_R8 ]

    ! -- begin
    _rc_init_

    ! -- grid_size sanity check
    _ufs_assert_log_(size(grid_size) >= 2,ESMF_RC_ARG_SIZE,"grid_size array size must be at least 2")

    ! -- create output lat/lon grid
    grid = ESMF_GridCreate1PeriDim( &
                   maxIndex  = grid_size, &
                   coordSys  = ESMF_COORDSYS_SPH_DEG, &
                   coordDep1 = (/ 1 /), &
                   coordDep2 = (/ 2 /), &
                   indexFlag = ESMF_INDEX_GLOBAL, &
                   _rc_)

    ! -- set up grid coordinates
    call ESMF_GridAddCoord(grid, _rc_)
    do item = 1, size(grid_size)
      call ESMF_GridGetCoord(grid, item, farrayPtr=xp, computationalLBound=lb, computationalUBound=ub, _rc_)
      dx = grid_domain(item,2) / grid_size(item)
      do j = lb(1), ub(1)
        xp(j) = grid_domain(item,1) + (j-1) * dx
      end do
    end do

  end function ufs_mpas_grid_create


  function ufs_mpas_mesh_create(vm, domain, rc) result (ufs_mesh)

    type(ESMF_VM),     intent(in)  :: vm
    type(domain_type), intent(in)  :: domain
    integer, optional, intent(out) :: rc

    type(ESMF_Mesh) :: ufs_mesh

    ! -- local variables
    _rc_var_define_
    _stat_var_define_
    integer                              :: item, iv, j
    integer                              :: numElems, numNodes, nHalo
    integer                              :: totalNodes, localPet
    integer,                 pointer     :: vertexDegree
    integer, dimension(:),   allocatable :: elemIds, elemTypes, elemConn
    integer, dimension(:),   allocatable :: nodeIds
    integer, dimension(:),   allocatable :: nodesOnPET, nodeOwners, nodesOnLocalPET
    integer, dimension(:),   pointer     :: indexToCellID, indexToVertexID, &
                                            nCellsArray, nVerticesArray
    integer, dimension(:,:), pointer     :: cellsOnVertex

    real(ESMF_KIND_R8), dimension(:), allocatable :: nodeCoords
    real(kind=RKIND),   dimension(:), pointer     :: latCell, lonCell

    type(mpas_pool_type), pointer :: mesh

    character(len=ESMF_MAXSTR) :: logm

    ! -- local parameters
    integer, parameter :: parametricDim = 2
    integer, parameter :: spatialDim    = 2

    ! -- begin
    _rc_init_

    ! -- retrieve MPAS mesh information
    call mpas_pool_get_subpool(domain % blocklist % structs, 'mesh', mesh)
    call mpas_pool_get_dimension(mesh,'nCellsArray',     nCellsArray)
    call mpas_pool_get_dimension(mesh,'nVerticesArray',  nVerticesArray)
    call mpas_pool_get_dimension(mesh,'vertexDegree',    vertexDegree)
    call mpas_pool_get_array    (mesh,'cellsOnVertex',   cellsOnVertex)
    call mpas_pool_get_array    (mesh,'indexToCellID',   indexToCellID)
    call mpas_pool_get_array    (mesh,'indexToVertexID', indexToVertexID)
    call mpas_pool_get_array    (mesh,'latCell',         latCell)
    call mpas_pool_get_array    (mesh,'lonCell',         lonCell)

    write(logm, '("ufs_mpas_mesh_create: nVerticesArray: ",l1)') associated(nVerticesArray)
    call ESMF_LogWrite(logm, _rc_)
    if (associated(nVerticesArray)) then
      write(logm, '("ufs_mpas_mesh_create: nVerticesArray: size/min/max",3i20)') size(nVerticesArray), minval(nVerticesArray), maxval(nVerticesArray)
      call ESMF_LogWrite(logm, _rc_)
    else
      write(logm, '("ufs_mpas_mesh_create: nVerticesArray: <null>")')
      call ESMF_LogWrite(logm, _rc_)
    end if

    ! -- set halo size
    nHalo = 1

    ! -- define dual mesh elements
    numElems = nVerticesArray(nHalo + 1)
    allocate(elemIds(numElems), elemTypes(numElems), elemConn(vertexDegree * numElems), _alloc_stat_)

    j = 0
    do item = 1, numElems
      elemIds  (item) = indexToVertexID(item)
      elemTypes(item) = ESMF_MESHELEMTYPE_TRI
      do iv = 1, vertexDegree
        j = j + 1
        elemConn(j) = cellsOnVertex(iv, item)
      end do
    end do

    ! -- define dual mesh nodes
    numNodes = nCellsArray(nHalo + 1)
    allocate(nodeIds(numNodes), nodeCoords(spatialDim * numNodes), _alloc_stat_)

    j = 1
    do item = 1, numNodes
      nodeIds(item)     = indexToCellID(item)
      nodeCoords(j    ) = lonCell(item)
      nodeCoords(j + 1) = latCell(item)
      j = j + spatialDim
    end do

    ! -- set node ownership according to MPAS decomposition
    call ESMF_VMGet(vm, localPet=localPet, _rc_)
    call ESMF_VMAllFullReduce(vm, (/nCellsArray(1)/), totalNodes, 1, ESMF_REDUCE_SUM, _rc_)
    write(logm, '("mesh_create: nodes: local, total: ",2i10)') nCellsArray(1), totalNodes
    call ESMF_LogWrite(logm, _rc_)

    allocate(nodesOnPET(totalNodes), nodesOnLocalPET(totalNodes), _alloc_stat_)
    nodesOnLocalPET = 0
    do j = 1, nCellsArray(1)
      nodesOnLocalPET(indexToCellID(j)) = localPet + 1
    end do
    call ESMF_VMAllReduce(vm, nodesOnLocalPET, nodesOnPET, totalNodes, ESMF_REDUCE_SUM, _rc_)
    write(logm, '("mesh_create: nodesOnPET: min, max: ",2i10)') minval(nodesOnPET), maxval(nodesOnPET)
    call ESMF_LogWrite(logm, _rc_)
    deallocate(nodesOnLocalPET, _deall_stat_)

    allocate(nodeOwners(numNodes), _alloc_stat_)
    do j = 1, numNodes
      nodeOwners(j) = nodesOnPET(indexToCellID(j)) - 1
    end do

    deallocate(nodesOnPET, _deall_stat_)
    
    ufs_mesh = ESMF_MeshCreate(parametricDim, spatialDim,      &
                               nodeIds, nodeCoords,            &
                               nodeOwners=nodeOwners,          &
                               elementIds=elemIds,             &
                               elementTypes=elemTypes,         &
                               elementConn=elemConn,           &
                               coordSys=ESMF_COORDSYS_SPH_RAD, &
                               _rc_)

    deallocate(nodeIds, nodeCoords, nodeOwners, elemIds, elemTypes, elemConn, _deall_stat_)

  end function ufs_mpas_mesh_create

end module ufs_mpas_geom
