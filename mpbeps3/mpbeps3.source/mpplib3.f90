!-----------------------------------------------------------------------
! Basic parallel PIC library for MPI communications with OpenMP
! mpplib3.f90 contains basic communications procedures for 2d partitions:
! PPINIT2 initializes parallel processing for Fortran90, returns
!         number of processors and processor id.
! PPEXIT terminates parallel processing.
! PPABORT aborts parallel processing.
! PWTIMERA performs parallel local wall clock timing.
! PPCOMM_T creates a transposed communicator
! PPSUM performs parallel sum of a real vector.
! PPDSUM performs parallel sum of a double precision vector.
! PPIMAX performs parallel maximum of an integer vector.
! PPDMAX performs parallel maximum of a double precision vector.
! PPDSCAN performs parallel prefix reduction of a double precision
!         vector
! PPDSCAN_T performs parallel prefix reduction of a double precision
!           vector with transposed communicator
! PPBICAST broadcasts integer data from node 0
! PPBDCAST broadcasts double precision data from node 0
! PPBICASTY performs a segmented broadcast of integer data in y
! PPBICASTYR performs a reverse segmented broadcast of integer data in y
! PPBICASTZ performs a segmented broadcast of integer data in z
! PPBICASTZR performs a reverse segmented broadcast of integer data in z
! PPISHFTR2 moves first part of an integer array to the right in y, and
!           second part of an integer array to the right in z.
! PPNCGUARD32L copies data to guard cells in y and z for scalar data,
!              linear interpolation, and distributed data with 2D
!              non-uniform partition.
! PPNAGUARD32L adds guard cells in y and z for scalar array, linear
!              interpolation, and distributed data with 2D non-uniform
!              partition.
! PPNACGUARD32L adds guard cells in y and z for vector array, linear
!               interpolation, and distributed data with 2D non-uniform
!               partition.
! PPFYMOVE32 moves fields into appropriate spatial regions in y, between
!            non-uniform and uniform partitions
! PPFZMOVE32 moves fields into appropriate spatial regions in z, between
!            non-uniform and uniform partitions
! PPTPOS3A performs a transpose of a complex scalar array, distributed
!          in y and z, to a complex scalar array, distributed in x and z
! PPTPOS3B performs a transpose of a complex scalar array, distributed
!          in x and z, to a complex scalar array, distributed in x and y
! PPNTPOS3A performs a transpose of an n component complex vector array,
!           distributed in y and z, to an n component complex vector
!           array, distributed in x and z.
! PPNTPOS3B performs a transpose of an n component complex vector array,
!           distributed in x and z, to an n component complex vector
!           array, distributed in x and y.
! PPMOVE32 moves particles in y/z into appropriate spatial regions with
!          periodic boundary conditions.  Assumes ihole list has been
!          found.
! PPPMOVE32 moves particles in y/z into appropriate spatial regions for
!           tiled distributed data with 2D spatial decomposition
! PPWRITE32 collects distributed real 3d scalar data f and writes to a
!           direct access binary file with 2D spatial decomposition
! PPREAD32 reads real 3d scalar data f from a direct access binary file
!          and distributes it with 2D spatial decomposition
! PPVWRITE32 collects distributed real 3d vector data f and writes to a
!            direct access binary file with 2D spatial decomposition
! PPVREAD32 reads real 3d vector data f from a direct access binary file
!           and distributes it with 2D spatial decomposition
! PPWRPART3 collects distributed particle data part and writes to a
!           fortran unformatted file with spatial decomposition
! PPRDPART3 reads particle data part from a fortran unformatted file and
!           distributes it with spatial decomposition
! PPWRDATA3 collects distributed periodic real 3d scalar data f and
!           writes to a fortran unformatted file
! PPRDDATA3 reads periodic real 3d scalar data f from a fortran
!           unformatted file and distributes it
! PPWRVDATA3 collects distributed periodic real 3d vector data f and
!            writes to a fortran unformatted file
! PPRDVDATA3 reads periodic real 3d vector data f from a fortran
!            unformatted file and distributes it
! PPWRVCDATA3 collects distributed periodic complex 3d vector data f and
!             writes to a fortran unformatted file with spatial
!             decomposition
! PPRDVCDATA3 reads periodic complex 3d vector data f from a fortran
!             unformatted file and distributes it with spatial
!             decomposition
! PPARTT3 collects distributed test particle data
! PPADJFVS3 adjusts 3d velocity distribution in different regions of
!           space, so that partial regions have equal grid points
! PPWRNCOMP3 collects distributed non-uniform partition information and
!            writes to a fortran unformatted file
! PPWRVNDATA3 collects distributed real 3d vector non-uniform data f and
!             writes to a fortran unformatted file
! written by viktor k. decyk, ucla
! copyright 1995, regents of the university of california
! update: March 21, 2018
      module mpplib3
      use mpi
      implicit none
!
! common data for parallel processing
! lstat = length of status array
      integer, parameter :: lstat = MPI_STATUS_SIZE
! nproc = number of real or virtual processors obtained
! lgrp = current communicator
! mreal = default datatype for reals
! mint = default datatype for integers
! mcplx = default datatype for complex type
! mdouble = default double precision type
! lworld = MPI_COMM_WORLD communicator
! mgrp = transposed communicator
      integer :: nproc, lgrp, mreal, mint, mcplx, mdouble, lworld, mgrp
! msum = MPI_SUM
! mmax = MPI_MAX
      integer :: msum, mmax
      save
!
      private
      public :: lstat, nproc, lgrp, mreal, mint, mcplx, mdouble, lworld
      public :: mgrp
      public :: PPINIT2, PPEXIT, PPABORT, PWTIMERA, PPCOMM_T
      public :: PPSUM, PPDSUM, PPMAX, PPIMAX, PPDMAX, PPDSCAN, PPDSCAN_T
      public :: PPBICAST, PPBDCAST, PPBICASTZ, PPBICASTZR
      public :: PPISHFTR2, PPNCGUARD32L, PPNAGUARD32L, PPNACGUARD32L
      public :: PPFYMOVE32, PPFZMOVE32
      public :: PPTPOS3A, PPTPOS3B, PPNTPOS3A, PPNTPOS3B
      public :: PPMOVE32, PPPMOVE32
      public :: PPWRITE32, PPREAD32, PPVWRITE32, PPVREAD32
      public :: PPWRPART3, PPRDPART3, PPWRDATA3, PPRDDATA3
      public :: PPWRVDATA3, PPRDVDATA3, PPWRVCDATA3, PPRDVCDATA3
      public :: PPARTT3, PPADJFVS3, PPWRNCOMP3, PPWRVNDATA3
!
      contains
!
!-----------------------------------------------------------------------
      subroutine PPINIT2(idproc,nvp)
! this subroutine initializes parallel processing
! lgrp communicator = MPI_COMM_WORLD
! output: idproc, nvp
! idproc = processor id in lgrp communicator
! nvp = number of real or virtual processors obtained
      implicit none
      integer, intent(inout) :: idproc, nvp
! nproc = number of real or virtual processors obtained
! lgrp = current communicator
! mreal = default datatype for reals
! mint = default datatype for integers
! mcplx = default datatype for complex type
! mdouble = default double precision type
! lworld = MPI_COMM_WORLD communicator
! msum = MPI_SUM
! mmax = MPI_MAX
! local data
      integer :: ierror, ndprec, idprec
      integer :: iprec
      logical :: flag
      real :: prec
! ndprec = (0,1) = (no,yes) use (normal,autodouble) precision
      if (digits(prec) > 24) then
         ndprec = 1
      else
         ndprec = 0
      endif
! idprec = (0,1) = (no,yes) use (normal,autodouble) integer precision
      if (digits(iprec) > 31) then
         idprec = 1
      else
         idprec = 0
      endif
! this segment is used for mpi computers
! indicate whether MPI_INIT has been called
      call MPI_INITIALIZED(flag,ierror)
      if (.not.flag) then
! initialize the MPI execution environment
         call MPI_INIT(ierror)
         if (ierror /= 0) stop
      endif
      lworld = MPI_COMM_WORLD
      lgrp = lworld
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierror)
! determine the size of the group associated with a communicator
      call MPI_COMM_SIZE(lgrp,nproc,ierror)
! set default datatypes
      mint = MPI_INTEGER
      mdouble = MPI_DOUBLE_PRECISION
! single precision real
      if (ndprec==0) then
         mreal = MPI_REAL
         mcplx = MPI_COMPLEX
! double precision real
      else
         mreal = MPI_DOUBLE_PRECISION
         mcplx = MPI_DOUBLE_COMPLEX
      endif
! single precision integer
!     if (idprec==0) then
!        mint = MPI_INTEGER
! double precision integer
!     else
!        mint = MPI_INTEGER8
!     endif
! operators
      msum = MPI_SUM
      mmax = MPI_MAX
      nvp = nproc
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPEXIT()
! this subroutine terminates parallel processing
      implicit none
! lworld = MPI_COMM_WORLD communicator
! local data
      integer :: ierror
      logical :: flag
! indicate whether MPI_INIT has been called
      call MPI_INITIALIZED(flag,ierror)
      if (flag) then
! synchronize processes
         call MPI_BARRIER(lworld,ierror)
! terminate MPI execution environment
         call MPI_FINALIZE(ierror)
      endif
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPABORT()
! this subroutine aborts parallel processing
      implicit none
! lworld = MPI_COMM_WORLD communicator
! local data
      integer :: errorcode, ierror
      logical :: flag
! indicate whether MPI_INIT has been called
      call MPI_INITIALIZED(flag,ierror)
      if (flag) then
         errorcode = 1
! terminate MPI execution environment
         call MPI_ABORT(lworld,errorcode,ierror)
      endif
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PWTIMERA(icntrl,time,dtime)
! this subroutine performs local wall clock timing
! input: icntrl, dtime
! icntrl = (-1,0,1) = (initialize,ignore,read) clock
! clock should be initialized before it is read!
! time = elapsed time in seconds
! dtime = current time
! written for mpi
      implicit none
      integer, intent(in) :: icntrl
      real, intent(inout) :: time
      double precision, intent(inout) :: dtime
! local data
      double precision :: jclock
! initialize clock
      if (icntrl==(-1)) then
         dtime = MPI_WTIME()
! read clock and write time difference from last clock initialization
      else if (icntrl==1) then
         jclock = dtime
         dtime = MPI_WTIME()
         time = real(dtime - jclock)
      endif
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPCOMM_T(nvpy,nvpz)
! this subroutine creates a transposed communicator
! nvpy/nvpz = number of real or virtual processors in y/z
      integer, intent(in) :: nvpy, nvpz
! local data
      integer idproc, js, ks, new, ierr
! lgrp = current communicator
! mgrp = transposed communicator
! find current processor id
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! js/ks = old processor co-ordinates in y/z => idproc = js + nvpy*ks
      ks = idproc/nvpy
      js = idproc - nvpy*ks
! new processor id
      new = ks + nvpz*js
! create a new communicator based on color and key
      call MPI_COMM_SPLIT(lgrp,1,new,mgrp,ierr)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPSUM(f,g,nxp)
! this subroutine performs a parallel sum of a vector, that is:
! f(j,k) = sum over k of f(j,k)
! at the end, all processors contain the same summation.
! f = input and output real data
! g = scratch real array
! nxp = number of data values in vector
      implicit none
      integer, intent(in) :: nxp
      real, dimension(nxp), intent(inout) :: f, g
! lgrp = current communicator
! mreal = default datatype for reals
! msum = MPI_SUM
! local data
      integer :: j, ierr
! return if only one processor
      if (nproc==1) return
! perform sum
      call MPI_ALLREDUCE(f,g,nxp,mreal,msum,lgrp,ierr)
! copy output from scratch array
      do j = 1, nxp
         f(j) = g(j)
      enddo
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPDSUM(f,g,nxp)
! this subroutine performs a parallel sum of a vector, that is:
! f(j,k) = sum over k of f(j,k)
! at the end, all processors contain the same summation.
! f = input and output double precision data
! g = scratch double precision array
! nxp = number of data values in vector
      implicit none
      integer, intent(in) :: nxp
      double precision, dimension(nxp), intent(inout) :: f, g
! lgrp = current communicator
! mdouble = default double precision type
! msum = MPI_SUM
! local data
      integer :: j, ierr
! return if only one processor
      if (nproc==1) return
! perform sum
      call MPI_ALLREDUCE(f,g,nxp,mdouble,msum,lgrp,ierr)
! copy output from scratch array
      do j = 1, nxp
         f(j) = g(j)
      enddo
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPMAX(f,g,nxp)
! this subroutine finds parallel maximum for each element of a vector
! that is, f(j,k) = maximum as a function of k of f(j,k)
! at the end, all processors contain the same maximum.
! f = input and output real data
! g = scratch real array
! nxp = number of data values in vector
      implicit none
      integer, intent(in) :: nxp
      real, dimension(nxp), intent(inout) :: f, g
! lgrp = current communicator
! mreal = default datatype for reals
! mmax = MPI_MAX
! local data
      integer j, ierr
! return if only one processor
      if (nproc==1) return
! find maximum
      call MPI_ALLREDUCE(f,g,nxp,mreal,mmax,lgrp,ierr)
! copy output from scratch array
      do j = 1, nxp
         f(j) = g(j)
      enddo
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPIMAX(if,ig,nxp)
! this subroutine finds parallel maximum for each element of a vector
! that is, if(j,k) = maximum as a function of k of if(j,k)
! at the end, all processors contain the same maximum.
! if = input and output integer data
! ig = scratch integer array
! nxp = number of data values in vector
      implicit none
      integer, intent(in) :: nxp
      integer, dimension(nxp), intent(inout) :: if, ig
! lgrp = current communicator
! mint = default datatype for integers
! mmax = MPI_MAX
! local data
      integer :: j, ierr
! return if only one processor
      if (nproc==1) return
! find maximum
      if (nproc > 1) then
         call MPI_ALLREDUCE(if,ig,nxp,mint,mmax,lgrp,ierr)
      endif
! copy output from scratch array
      do j = 1, nxp
         if(j) = ig(j)
      enddo
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPDMAX(f,g,nxp)
! this subroutine finds parallel maximum for each element of a vector
! that is, f(j,k) = maximum as a function of k of f(j,k)
! at the end, all processors contain the same maximum.
! f = input and output double precision data
! g = scratch double precision array
! nxp = number of data values in vector
      implicit none
      integer, intent(in) :: nxp
      double precision, dimension(nxp), intent(inout) :: f, g
! lgrp = current communicator
! mdouble = default double precision type
! mmax = MPI_MAX
! local data
      integer j, ierr
! return if only one processor
      if (nproc==1) return
! find maximum
      call MPI_ALLREDUCE(f,g,nxp,mdouble,mmax,lgrp,ierr)
! copy output from scratch array
      do j = 1, nxp
         f(j) = g(j)
      enddo
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPDSCAN(f,g,nxp)
! this subroutine performs a parallel prefix reduction of a vector,
! that is: f(j,k) = sum over k of f(j,k), where the sum is over k values
! less than idproc.
! f = input and output double precision data
! g = scratch double precision array
! nxp = number of data values in vector
      implicit none
      integer, intent(in) :: nxp
      double precision, dimension(nxp), intent(inout) :: f, g
! lgrp = current communicator
! mdouble = default double precision type
! msum = MPI_SUM
! local data
      integer :: j, ierr
! return if only one processor
      if (nproc==1) return
! performs a parallel prefixm sum
       call MPI_SCAN(f,g,nxp,mdouble,msum,lgrp,ierr)
! copy output from scratch array
      do j = 1, nxp
         f(j) = g(j)
      enddo
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPDSCAN_T(f,g,nxp)
! this subroutine performs a parallel prefix reduction of a vector,
! that is: f(j,k) = sum over k of f(j,k), where the sum is over k values
! less than idproc.  using transposed communicator mgrp
! f = input and output double precision data
! g = scratch double precision array
! nxp = number of data values in vector
      implicit none
      integer, intent(in) :: nxp
      double precision, dimension(nxp), intent(inout) :: f, g
! lgrp = current communicator
! mdouble = default double precision type
! msum = MPI_SUM
! local data
      integer :: j, ierr
! return if only one processor
      if (nproc==1) return
! performs a parallel prefixm sum
       call MPI_SCAN(f,g,nxp,mdouble,msum,mgrp,ierr)
! copy output from scratch array
      do j = 1, nxp
         f(j) = g(j)
      enddo
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPBICAST(if,nxp)
! this subroutine broadcasts integer data from node 0
! if = input and output integer data
! nxp = number of data values
      implicit none
      integer, intent(in) :: nxp
      integer, dimension(nxp), intent(inout) :: if
! nproc = number of real or virtual processors obtained
! lgrp = current communicator
! mint = default datatype for integers
! local data
      integer :: ierr
! return if only one processor
      if (nproc==1) return
! broadcast integer
      call MPI_BCAST(if,nxp,mint,0,lgrp,ierr)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPBDCAST(f,nxp)
! this subroutine broadcasts double precision data from node 0
! f = input and output double precision data
! nxp = number of data values
      implicit none
      integer, intent(in) :: nxp
      double precision, dimension(nxp), intent(inout) :: f
! nproc = number of real or virtual processors obtained
! lgrp = current communicator
! mdouble = default double precision type
! local data
      integer :: ierr
! return if only one processor
      if (nproc==1) return
! broadcast integer
      call MPI_BCAST(f,nxp,mdouble,0,lgrp,ierr)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPBICASTZ(if,nxp,nvpy,nvpz)
! this subroutine performs a segmented broadcast of integer data in z
! data from the first node in each z row is broadcast to all the other
! nodes in that row
! if = input and output integer data
! nxp = number of data values
! nvpy/nvpz = number of real or virtual processors in y/z
      implicit none
      integer, intent(in) :: nxp, nvpy, nvpz
      real, dimension(nxp), intent(inout) :: if
! lgrp = current communicator
! mint = default datatype for integerss
! local data
      integer :: i, idproc, js, ks, id, ltag, ierr
      integer, dimension(lstat) :: istatus
! find processor id
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! js/ks = processor co-ordinates in y/z => idproc = js + nvpy*ks
      ks = idproc/nvpy
      js = idproc - nvpy*ks
      ltag = nxp + 3
! return if only one processor
      if (nproc==1) return
      if (ks > 0) then
            call MPI_RECV(if,nxp,mint,js,ltag,lgrp,istatus,ierr)
      else if (ks==0) then
         do i = 2, nvpz
            id = js + nvpy*(i - 1)
            call MPI_SEND(if,nxp,mint,id,ltag,lgrp,ierr)
         enddo
      endif
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPBICASTZR(if,nxp,nvpy,nvpz)
! this subroutine performs a reverse segmented broadcast of integer data
! in z. data from the last node in each z row is broadcast to all the
! other nodes in that row
! if = input and output integer data
! nxp = number of data values
! nvpy/nvpz = number of real or virtual processors in y/z
      implicit none
      integer, intent(in) :: nxp, nvpy, nvpz
      real, dimension(nxp), intent(inout) :: if
! lgrp = current communicator
! mint = default datatype for integerss
! local data
      integer :: i, idproc, js, ks, joff, nvpz1, id, ltag, ierr
      integer, dimension(lstat) :: istatus
! find processor id
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! js/ks = processor co-ordinates in y/z => idproc = js + nvpy*ks
      ks = idproc/nvpy
      js = idproc - nvpy*ks
      nvpz1 = nvpz - 1
      joff = js + nvpy*nvpz1
      ltag = nxp + 4
! return if only one processor
      if (nproc==1) return
      if (ks < nvpz1) then
         call MPI_RECV(if,nxp,mint,joff,ltag,lgrp,istatus,ierr)
      else if (ks==nvpz1) then
         do i = 1, nvpz1
            id = js + nvpy*(i - 1)
            call MPI_SEND(if,nxp,mint,id,ltag,lgrp,ierr)
         enddo
      endif
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPISHFTR2(if,ig,nxp,nvpy,nvpz)
! this subroutine moves first part of an integer array to the right in y
! and second part of an integer array to the right in z
! with periodic boundary conditions
! if = input and output integer data
! ig = scratch integer array
! nxp = number of data values in vector in each dimension
! nvpy/nvpz = number of real or virtual processors in y/z
      implicit none
      integer, intent(in) :: nxp, nvpy, nvpz
      integer, dimension(nxp,2), intent(inout) :: if, ig
! lgrp = current communicator
! mint = default datatype for integers
! local data
      integer :: idproc, nvp, jb, kb, kr, kl, ltag, j, ierr
      integer :: msid
      integer, dimension(lstat) :: istatus
! find processor id
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! find number of processors
      call MPI_COMM_SIZE(lgrp,nvp,ierr)
! return if only one processor
      if (nvp==1) return
! determine neighbors
      kb = idproc/nvpy
      jb = idproc - nvpy*kb
! find right and left neighbors in y
      kr = jb + 1
      if (kr >= nvpy) kr = kr - nvpy
      kl = jb - 1
      if (kl < 0)  kl = kl + nvpy
      ltag = nxp + 1
! perform right shift in y for first part of data
      call MPI_IRECV(ig(1,1),nxp,mint,kl,ltag,lgrp,msid,ierr)
      call MPI_SEND(if(1,1),nxp,mint,kr,ltag,lgrp,ierr)
      call MPI_WAIT(msid,istatus,ierr)
! find right and left neighbors in z
      kr = kb + 1
      if (kr >= nvpz) kr = kr - nvpz
      kl = kb - 1
      if (kl < 0)  kl = kl + nvpz
      kr = nvpy*kr
      kl = nvpy*kl
      ltag = ltag + 1
! perform right shift in z for second part of data
      call MPI_IRECV(ig(1,2),nxp,mint,kl,ltag,lgrp,msid,ierr)
      call MPI_SEND(if(1,2),nxp,mint,kr,ltag,lgrp,ierr)
      call MPI_WAIT(msid,istatus,ierr)
! copy output from scratch array
      do j = 1, nxp
         if(j,1) = ig(j,1)
         if(j,2) = ig(j,2)
      enddo
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPNCGUARD32L(f,scs,nyzp,kstrt,nvpy,nvpz,nxv,nypmx,nzpmx&
     &,idds)
! this subroutine copies data to guard cells in non-uniform partitions
! f(j,k,l) = real data for grid j,k,l in particle partition.
! the grid is non-uniform and includes one extra guard cell.
! scs(j,k) = scratch array for particle partition
! nyzp(1:2) = number of primary gridpoints in y/z in particle partition
! kstrt = starting data block number
! nvpy/nvpz = number of real or virtual processors in y/z
! nxv = first dimension of f, must be >= nx
! nypmx = maximum size of particle partition in y, including guard cells
! nzpmx = maximum size of particle partition in z, including guard cells
! idds = dimensionality of domain decomposition
! linear interpolation, for distributed data,
! with 2D spatial decomposition
      implicit none
      integer, intent(in) :: kstrt, nvpy, nvpz, nxv, nypmx, nzpmx, idds
      real, dimension(nxv,nypmx,nzpmx), intent(inout) :: f
      real, dimension(nxv,nzpmx,2), intent(inout) :: scs
      integer, dimension(idds), intent(in) :: nyzp
! lgrp = current communicator
! mreal = default datatype for reals
! local data
      integer :: j, k, js, ks, noff, kr, kl
      integer :: nxvz, nxvzs, nxvy, nxvys, nyp1, nzp1
      integer :: msid, ierr
      integer, dimension(lstat) :: istatus
      nyp1 = nyzp(1) + 1
      nzp1 = nyzp(2) + 1
! js/ks = processor co-ordinates in y/z => idproc = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      noff = nypmx*nzpmx
      nxvz = nxv*nzpmx
      nxvy = nxv*nypmx
! special case for one processor in y
      if (nvpy==1) then
!$OMP PARALLEL DO PRIVATE(j,k)
         do k = 1, nyzp(2)
            do j = 1, nxv
               f(j,nyp1,k) = f(j,1,k)
            enddo
         enddo
!$OMP END PARALLEL DO
      else
! buffer data in y
!$OMP PARALLEL DO PRIVATE(j,k)
         do k = 1, nyzp(2)
            do j = 1, nxv
               scs(j,k,1) = f(j,1,k)
            enddo
         enddo
!$OMP END PARALLEL DO
! copy to guard cells in y
         nxvzs = nxv*nyzp(2)
         kr = js + 1
         if (kr >= nvpy) kr = kr - nvpy
         kl = js - 1
         if (kl < 0) kl = kl + nvpy
         kr = kr + nvpy*ks
         kl = kl + nvpy*ks
! this segment is used for mpi computers
         call MPI_IRECV(scs(1,1,2),nxvz,mreal,kr,noff+3,lgrp,msid,ierr)
         call MPI_SEND(scs,nxvzs,mreal,kl,noff+3,lgrp,ierr)
         call MPI_WAIT(msid,istatus,ierr)
! copy guard cells
!$OMP PARALLEL DO PRIVATE(j,k)
         do k = 1, nyzp(2)
            do j = 1, nxv
               f(j,nyp1,k) = scs(j,k,2)
           enddo
         enddo
!$OMP END PARALLEL DO
      endif
! special case for one processor in z
      if (nvpz==1) then
!$OMP PARALLEL DO PRIVATE(j,k)
         do k = 1, nyp1
            do j = 1, nxv
               f(j,k,nzp1) = f(j,k,1)
            enddo
         enddo
!$OMP END PARALLEL DO
         return
      endif
! copy to guard cells in z
      nxvys = nxv*nyp1
      kr = ks + 1
      if (kr >= nvpz) kr = kr - nvpz
      kl = ks - 1
      if (kl < 0) kl = kl + nvpz
      kr = js + nvpy*kr
      kl = js + nvpy*kl
! this segment is used for mpi computers
      call MPI_IRECV(f(1,1,nzp1),nxvy,mreal,kr,noff+4,lgrp,msid,ierr)
      call MPI_SEND(f,nxvys,mreal,kl,noff+4,lgrp,ierr)
      call MPI_WAIT(msid,istatus,ierr)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPNAGUARD32L(f,scs,scr,nyzp,kstrt,nvpy,nvpz,nx,nxv,    &
     &nypmx,nzpmx,idds)
! this subroutine adds data from guard cells in non-uniform partitions
! f(j,k,l) = real data for grid j,k,l in particle partition.
! the grid is non-uniform and includes one extra guard cell.
! scs/scr = scratch arrays for particle partition
! nyzp(1:2) = number of primary gridpoints in y/z in particle partition
! kstrt = starting data block number
! nvpy/nvpz = number of real or virtual processors in y/z
! nx = system length in x direction
! nxv = first dimension of f, must be >= nx+1
! nypmx = maximum size of particle partition in y, including guard cells
! nzpmx = maximum size of particle partition in z, including guard cells
! idds = dimensionality of domain decomposition
! linear interpolation, for distributed data
! with 2D spatial decomposition
      implicit none
      integer, intent(in) :: kstrt, nvpy, nvpz, nx, nxv, nypmx, nzpmx
      integer, intent(in) :: idds
      real, dimension(nxv,nypmx,nzpmx), intent(inout) :: f
      real, dimension(nxv,nzpmx,2), intent(inout) :: scs
      real, dimension(nxv,nypmx), intent(inout) :: scr
      integer, dimension(idds), intent(in) :: nyzp
! lgrp = current communicator
! mreal = default datatype for reals
! local data
      integer :: j, k, js, ks, noff, kr, kl
      integer :: nx1, nxvz, nxvzs, nxvy, nxvys, nyp1, nzp1
      integer :: msid, ierr
      integer, dimension(lstat) :: istatus
      nx1 = nx + 1
      nyp1 = nyzp(1) + 1
      nzp1 = nyzp(2) + 1
! js/ks = processor co-ordinates in y/z => idproc = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      noff = nypmx*nzpmx
      nxvz = nxv*nzpmx
      nxvy = nxv*nypmx
! special case for one processor in y
      if (nvpy==1) then
!$OMP PARALLEL DO PRIVATE(j,k)
         do k = 1, nzp1
            do j = 1, nx1
               f(j,1,k) = f(j,1,k) + f(j,nyp1,k)
               f(j,nyp1,k) = 0.0
            enddo
         enddo
!$OMP END PARALLEL DO
      else
! buffer data in y
!$OMP PARALLEL DO PRIVATE(j,k)
         do k = 1, nzp1 
            do j = 1, nxv
               scs(j,k,1) = f(j,nyp1,k)
            enddo
         enddo
!$OMP END PARALLEL DO
! add guard cells in y
         nxvzs = nxv*nzp1
         kr = js + 1
         if (kr >= nvpy) kr = kr - nvpy
         kl = js - 1
         if (kl < 0) kl = kl + nvpy
         kr = kr + nvpy*ks
         kl = kl + nvpy*ks
! this segment is used for mpi computers
         call MPI_IRECV(scs(1,1,2),nxvz,mreal,kl,noff+1,lgrp,msid,ierr)
         call MPI_SEND(scs,nxvzs,mreal,kr,noff+1,lgrp,ierr)
         call MPI_WAIT(msid,istatus,ierr)
! add up the guard cells
!$OMP PARALLEL DO PRIVATE(j,k)
         do k = 1, nzp1
            do j = 1, nx1
               f(j,1,k) = f(j,1,k) + scs(j,k,2)
               f(j,nyp1,k) = 0.0
            enddo
         enddo
!$OMP END PARALLEL DO
      endif
! special case for one processor in z
      if (nvpz==1) then
!$OMP PARALLEL DO PRIVATE(j,k)
         do k = 1, nyp1
            do j = 1, nx1
               f(j,k,1) = f(j,k,1) + f(j,k,nzp1)
               f(j,k,nzp1) = 0.0
            enddo
         enddo
!$OMP END PARALLEL DO
         return
      endif
! add guard cells in z
      nxvys = nxv*nyp1
      kr = ks + 1
      if (kr >= nvpz) kr = kr - nvpz
      kl = ks - 1
      if (kl < 0) kl = kl + nvpz
      kr = js + nvpy*kr
      kl = js + nvpy*kl
! this segment is used for mpi computers
      call MPI_IRECV(scr,nxvy,mreal,kl,noff+2,lgrp,msid,ierr)
      call MPI_SEND(f(1,1,nzp1),nxvys,mreal,kr,noff+2,lgrp,ierr)
      call MPI_WAIT(msid,istatus,ierr)
! add up the guard cells
!$OMP PARALLEL DO PRIVATE(j,k)
      do k = 1, nyp1
         do j = 1, nx1
            f(j,k,1) = f(j,k,1) + scr(j,k)
            f(j,k,nzp1) = 0.0
         enddo
      enddo
!$OMP END PARALLEL DO
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPNACGUARD32L(f,scs,scr,nyzp,ndim,kstrt,nvpy,nvpz,nx,  &
     &nxv,nypmx,nzpmx,idds)
! this subroutine adds data from guard cells in non-uniform partitions
! f(ndim,j,k,l) = real data for grid j,k,l in particle partition.
! the grid is non-uniform and includes one extra guard cell.
! scs/scr = scratch arrays for particle partition
! nyzp(1:2) = number of primary gridpoints in y/z in particle partition
! ndim = leading dimension of array f
! kstrt = starting data block number
! nvpy/nvpz = number of real or virtual processors in y/z
! nx = system length in x direction
! nxv = second dimension of f, must be >= nx+1
! nypmx = maximum size of particle partition in y, including guard cells
! nzpmx = maximum size of particle partition in z, including guard cells
! idds = dimensionality of domain decomposition
! linear interpolation, for distributed data
! with 2D spatial decomposition
      implicit none
      integer, intent(in) :: ndim, kstrt, nvpy, nvpz, nx, nxv
      integer, intent(in) :: nypmx, nzpmx, idds
      real, dimension(ndim,nxv,nypmx,nzpmx), intent(inout) :: f
      real, dimension(ndim,nxv,nzpmx,2), intent(inout) :: scs
      real, dimension(ndim,nxv,nypmx), intent(inout) :: scr
      integer, dimension(idds), intent(in) :: nyzp
! lgrp = current communicator
! mreal = default datatype for reals
! local data
      integer :: i, j, k, js, ks, noff, kr, kl
      integer :: nx1, nxvz, nxvzs, nxvy, nxvys, nyp1, nzp1
      integer :: msid, ierr
      integer, dimension(lstat) :: istatus
      nx1 = nx + 1
      nyp1 = nyzp(1) + 1
      nzp1 = nyzp(2) + 1
! js/ks = processor co-ordinates in y/z => idproc = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      noff = ndim*nypmx*nzpmx
      nxvz = ndim*nxv*nzpmx
      nxvy = ndim*nxv*nypmx
! special case for one processor in y
      if (nvpy==1) then
!$OMP PARALLEL DO PRIVATE(i,j,k)
         do k = 1, nzp1
            do j = 1, nx1
               do i = 1, ndim
                  f(i,j,1,k) = f(i,j,1,k) + f(i,j,nyp1,k)
                  f(i,j,nyp1,k) = 0.0
               enddo
            enddo
         enddo
!$OMP END PARALLEL DO
      else
! buffer data in y
!$OMP PARALLEL DO PRIVATE(i,j,k)
         do k = 1, nzp1 
            do j = 1, nxv
               do i = 1, ndim
                  scs(i,j,k,1) = f(i,j,nyp1,k)
               enddo
            enddo
         enddo
!$OMP END PARALLEL DO
! add guard cells in y
         nxvzs = ndim*nxv*nzp1
         kr = js + 1
         if (kr >= nvpy) kr = kr - nvpy
         kl = js - 1
         if (kl < 0) kl = kl + nvpy
         kr = kr + nvpy*ks
         kl = kl + nvpy*ks
! this segment is used for mpi computers
         call MPI_IRECV(scs(1,1,1,2),nxvz,mreal,kl,noff+1,lgrp,msid,ierr&
     &)
         call MPI_SEND(scs,nxvzs,mreal,kr,noff+1,lgrp,ierr)
         call MPI_WAIT(msid,istatus,ierr)
! add up the guard cells
!$OMP PARALLEL DO PRIVATE(i,j,k)
         do k = 1, nzp1
           do j = 1, nx1
              do i = 1, ndim
                  f(i,j,1,k) = f(i,j,1,k) + scs(i,j,k,2)
                  f(i,j,nyp1,k) = 0.0
               enddo
            enddo
         enddo
!$OMP END PARALLEL DO
      endif
! special case for one processor in z
      if (nvpz==1) then
!$OMP PARALLEL DO PRIVATE(i,j,k)
         do k = 1, nyp1
            do j = 1, nx1
               do i = 1, ndim
                  f(i,j,k,1) = f(i,j,k,1) + f(i,j,k,nzp1)
                  f(i,j,k,nzp1) = 0.0
               enddo
            enddo
         enddo
!$OMP END PARALLEL DO
         return
      endif
! add guard cells in z
      nxvys = ndim*nxv*nyp1
      kr = ks + 1
      if (kr >= nvpz) kr = kr - nvpz
      kl = ks - 1
      if (kl < 0) kl = kl + nvpz
      kr = js + nvpy*kr
      kl = js + nvpy*kl
! this segment is used for mpi computers
      call MPI_IRECV(scr,nxvy,mreal,kl,noff+2,lgrp,msid,ierr)
      call MPI_SEND(f(1,1,1,nzp1),nxvys,mreal,kr,noff+2,lgrp,ierr)
      call MPI_WAIT(msid,istatus,ierr)
! add up the guard cells
!$OMP PARALLEL DO PRIVATE(i,j,k)
      do k = 1, nyp1
         do j = 1, nx1
            do i = 1, ndim
               f(i,j,k,1) = f(i,j,k,1) + scr(i,j,k)
               f(i,j,k,nzp1) = 0.0
            enddo
         enddo
      enddo
!$OMP END PARALLEL DO
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPFYMOVE32(f,g,h,noff,nyzp,noffs,nyzps,noffd,nyzpd,    &
     &isign,kyp,kzp,ny,nz,kstrt,nvpy,nvpz,nxv,nypmx,nzpmx,idds,mter,ierr&
     &)
! this subroutine moves fields into appropriate spatial regions in y,
! between non-uniform and uniform partitions
! f(j,k,l) = real data for grid j,k,l in field partition.
! the grid is non-uniform and includes extra guard cells.
! output: f, g, h, ierr, and possibly mter
! g(j,k*l)/h(j,k*l) = scratch data for grid j,k,l in field partition.
! noff(1) = lowermost global gridpoint in y in particle partition
! noff(2) = backmost global gridpoint in z in particle partition
! nyzp(1:2) = number of primary (complete) gridpoints in y/z
! noffs/nyzps = source or scratch arrays for field partition
! noffd/nyzpd = destination or scratch arrays for field partition
! isign = -1, move from non-uniform (noff(1)/nyzp(1)) to uniform (kyp)
!    fields    Procedure PPFZMOVE32 should be called first
! isign = 1, move from uniform (kyp) to non-uniform (noff(1)/nyzp(1))
!    fields
! if isign = 0, the noffs(1)/nyzps(1) contains the source partition,
!    noffd(1)/nyzpd(1) contains the destination partition, and
!    noff(1)/nyzp(1), kyp are not used.  the partitions
!    noffs(1)/nyzps(1) and noffd(1)/nyzpd(1) are modified.
! kyp/kzp = number of complex grids in y/z in each uniform field
!    partition.
! ny/nz = global number of grids in y/z
! kstrt = starting data block number
! nvpy/nvpz = number of real or virtual processors in y/z
! nxv = first dimension of f, must be >= nx
! nypmx = maximum size of field partition in y, must be >= kyp+1
! nzpmx = maximum size of field partition in z, must be >= kzp+1
! idds = dimensionality of domain decomposition = 2
! mter = number of shifts required
! if mter = 0, then number of shifts is determined and returned
! ierr = (0,1) = (no,yes) error condition exists
      implicit none
      integer, intent(in) :: isign, kyp, kzp, ny, nz, kstrt, nvpy, nvpz
      integer, intent(in) :: nxv, nypmx, nzpmx, idds
      integer, intent(inout) :: mter, ierr
      real, dimension(nxv,nypmx,nzpmx), intent(inout) :: f
      real, dimension(nxv,nypmx*nzpmx) :: g, h
      integer, dimension(idds), intent(in) :: noff, nyzp
      integer, dimension(idds), intent(inout) :: noffs, nyzps
      integer, dimension(idds), intent(inout) :: noffd, nyzpd
! lgrp = current communicator
! mint = default datatype for integers
! mreal = default datatype for reals
! local data
      integer :: j, k, l, nbsize, js, ks, id, kyps, kzps, iter, npr, nps
      integer :: nter, koff, loff, kl, kr, kk, nypmn, itermax
      integer, dimension(2) :: jsl, jsr, ibflg, iwork
      integer :: msid
      integer, dimension(lstat) :: istatus
! exit if certain flags are set
      if ((mter < 0).or.(nvpy==1)) return
! find processor id and offsets in y/z
! js/ks = processor co-ordinates in x/y => id = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      kyps = min(kyp,max(0,ny-kyp*js))
      kzps = min(kzp,max(0,nz-kzp*ks))
      id = js + nvpy*ks
      nbsize = nxv*nypmx*nzpmx
      nypmn = nypmx
      iter = 2
      itermax = 200
      ierr = 0
      koff = min(kyp*js,ny)
! kl/kr = processor location for grid point ny/nz
      kl = (ny - 1)/kyp
      kr = (nz - 1)/kzp
! move from non-uniform in y to uniform fields
      if (isign < 0) then
! set partition parameters
         noffs(1) = noff(1)
         nyzps(1) = nyzp(1)
         nyzps(2) = kzps
         noffd(1) = koff
         nyzpd(1) = kyps
! extend partition to include ny+1 grid
! for non-uniform partition, append on last processor in y
         if (js==(nvpy-1)) nyzps(1) = nyzps(1) + 1
! for uniform partition, append just after ny grid point
         if (js==kl) nyzpd(1) = nyzpd(1) + 1
         if (js > kl) noffd(1) = noffd(1) + 1
! extend partition to include nz+1 grid
! for uniform partition, append just after nz grid point
         if (ks==kr) nyzps(2) = nyzps(2) + 1
! move from uniform to non-uniform field in y
      else if (isign > 0) then
! set partition parameters
         noffs(1) = koff
         nyzps(1) = kyps
         nyzps(2) = kzps
         noffd(1) = noff(1)
         nyzpd(1) = nyzp(1)
! extend partition to include ny+1 grid
! for non-uniform partition, append on last processor in y
         if (js==(nvpy-1)) nyzpd(1) = nyzpd(1) + 1
! for uniform partition, append just after ny grid point
         if (js==kl) nyzps(1) = nyzps(1) + 1
         if (js > kl) noffs(1) = noffs(1) + 1
! extend partition to include nz+1 grid
! for uniform partition, append just after nz grid point
         if (ks==kr) nyzps(2) = nyzps(2) + 1
! move from non-uniform to non-uniform fields
      else
! extend partitions to include (ny+1,nz+1) grids
         if (js==(nvpy-1)) then
            nyzps(1) = nyzps(1) + 1
            nyzpd(1) = nyzpd(1) + 1
         endif
         if (ks==nvpz-1) then
            nyzps(2) = nyzps(2) + 1
            nyzpd(2) = nyzpd(2) + 1
         endif
      endif
! main iteration loop
! determine number of outgoing grids
   10 kl = noffd(1)
      kr = kl + nyzpd(1)
      jsl(1) = 0
      jsr(1) = 0
      do k = 1, nyzps(1)
         kk = k + noffs(1)
! fields going right
         if (kk > kr) then
            jsr(1) = jsr(1) + 1
! fields going left
         else if (kk <= kl) then
            jsl(1) = jsl(1) + 1
         endif
      enddo
! copy fields
      iter = iter + 1
      npr = 0
      nter = 0
!
! get fields from left
      kr = id + 1
      kl = id - 1
      jsl(2) = 0
      jsr(2) = 0
      nps = nxv*jsr(1)*nyzps(2)
      koff = min(nyzps(1)-jsr(1)+1,nypmx) - 1
! buffer outgoing data
!$OMP PARALLEL DO PRIVATE(j,k,l,loff)
      do l = 1, nyzps(2)
         loff = jsr(1)*(l - 1)
         do k = 1, jsr(1)
            do j = 1, nxv
               g(j,k+loff) = f(j,k+koff,l)
            enddo
         enddo
      enddo
!$OMP END PARALLEL DO
! this segment is used for mpi computers
! post receive from left
      if (js > 0) then
         call MPI_IRECV(h,nbsize,mreal,kl,iter,lgrp,msid,ierr)
      endif
! send fields to right
      if (js < (nvpy-1)) then
         call MPI_SEND(g,nps,mreal,kr,iter,lgrp,ierr)
      endif
! wait for fields to arrive
      if (js > 0) then
         call MPI_WAIT(msid,istatus,ierr)
         call MPI_GET_COUNT(istatus,mreal,nps,ierr)
! assumes nyzps(2) is same for sender and receiver
         if (nps > 0) jsl(2) = nps/(nxv*nyzps(2))
      endif
! adjust field size
      nyzps(1) = nyzps(1) - jsr(1)
! do not allow move to overflow field array
      jsr(1) = max0((nyzps(1)+jsl(2)-nypmn),0)
      if (jsr(1) > 0) then
         nyzps(1) = nyzps(1) - jsr(1)
         npr = max0(npr,jsr(1))
! save whatever is possible into end of h
         kk = min0(jsr(1),nypmn-jsl(2))
!$OMP PARALLEL DO PRIVATE(j,k,l,loff)
         do l = 1, nyzps(2)
            loff = jsl(2)*(l - 1)
            do k = 1, kk
              do j = 1, nxv
                  h(j,k+nypmn-kk+loff) = f(j,nyzps(1)+k,l)
               enddo
            enddo
         enddo
!$OMP END PARALLEL DO
      endif
! shift data which is staying, if necessary
      if ((nyzps(1) > 0).and.(jsl(2) > 0)) then
         do k = 1, nyzps(1)
            kk = nyzps(1) - k + 1
!$OMP PARALLEL DO PRIVATE(j,l)
            do l = 1, nyzps(2)
               do j = 1, nxv
                  f(j,kk+jsl(2),l) = f(j,kk,l)
               enddo
            enddo
!$OMP END PARALLEL DO
         enddo
      endif
! insert data coming from left
!$OMP PARALLEL DO PRIVATE(j,k,l,loff)
      do l = 1, nyzps(2)
         loff = jsl(2)*(l - 1)
         do k = 1, jsl(2)
            do j = 1, nxv
               f(j,k,l) = h(j,k+loff)
            enddo
         enddo
      enddo
!$OMP END PARALLEL DO
! adjust field size and offset
      nyzps(1) = nyzps(1) + jsl(2)
      noffs(1) = noffs(1) - jsl(2)
!
! get fields from right
      kr = id + 1
      kl = id - 1
      nps = nxv*jsl(1)*nyzps(2)
      iter = iter + 1
! buffer outgoing data
!$OMP PARALLEL DO PRIVATE(j,k,l,loff)
      do l = 1, nyzps(2)
         loff = jsl(1)*(l - 1)
         do k = 1, jsl(1)
            do j = 1, nxv
               g(j,k+loff) = f(j,k,l)
            enddo
         enddo
      enddo
!$OMP END PARALLEL DO
! this segment is used for mpi computers
! post receive from right
      if (js < (nvpy-1)) then
         call MPI_IRECV(h,nbsize,mreal,kr,iter,lgrp,msid,ierr)
      endif
! send fields to left
      if (js > 0) then
         call MPI_SEND(g,nps,mreal,kl,iter,lgrp,ierr)
      endif
! wait for fields to arrive
      if (js < (nvpy-1)) then
         call MPI_WAIT(msid,istatus,ierr)
         call MPI_GET_COUNT(istatus,mreal,nps,ierr)
! assumes nyzps(2) is same for sender and receiver
         if (nps > 0) jsr(2) = nps/(nxv*nyzps(2))
      endif
! adjust field size
      nyzps(1) = nyzps(1) - jsl(1)
      noffs(1) = noffs(1) + jsl(1)
! shift data which is staying, if necessary
      if ((nyzps(1) > 0).and.(jsl(1) > 0)) then
         do k = 1, nyzps(1)
!$OMP PARALLEL DO PRIVATE(j,l)
            do l = 1, nyzps(2)
               do j = 1, nxv
                  f(j,k,l) = f(j,k+jsl(1),l)
               enddo
           enddo
!$OMP END PARALLEL DO
        enddo
      endif
! do not allow move to overflow field array
      jsl(1) = max0((nyzps(1)+jsr(2)-nypmn),0)
      if (jsl(1) > 0) then
         npr = max0(npr,jsl(1))
         jsr(2) = jsr(2) - jsl(1)
      endif
! process if no prior error
      if ((jsl(1) > 0).or.(jsr(1) <= 0)) then
! insert data coming from right
!$OMP PARALLEL DO PRIVATE(j,k,l,loff)
         do l = 1, nyzps(2)
            loff = jsr(2)*(l - 1)
            do k = 1, jsr(2)
               do j = 1, nxv
                  f(j,k+nyzps(1),l) = h(j,k+loff)
               enddo
            enddo
         enddo
!$OMP END PARALLEL DO
! adjust field size and offset
         nyzps(1) = nyzps(1) + jsr(2)
      endif
! check if desired partition is achieved
      if (nyzps(2) > 0) then
         nter = nter + abs(nyzps(1)-nyzpd(1)) + abs(noffs(1)-noffd(1))
      endif
! calculate number of iterations
      nps = iter/2 - 1
      if (nps <= mter) then
! process errors
! should not happen, other processors do not know about this error
         if (npr /= 0) then
            ierr = npr
            write (*,*) kstrt, 'local field overflow error, ierr=', ierr
            return
         endif
! continue iteration
         if (nps < mter) go to 10
         return
      endif
! check errors, executed only first time, when mter = 0
      ibflg(1) = npr
      ibflg(2) = nter
      call PPIMAX(ibflg,iwork,2)
! field overflow error
      if (ibflg(1) /= 0) then
         ierr = ibflg(1)
         if (kstrt==1) then
            write (*,*) 'global field overflow error, ierr = ', ierr
         endif
         return
      endif
! check if any fields have to be passed further
      if (ibflg(2) > 0) then
!        if (kstrt==1) then
!           write (2,*) 'Info: fields being passed further = ', ibflg(2)
!        endif
! continue iteration
         if (iter < itermax) go to 10
         ierr = -((iter-2)/2)
         if (kstrt==1) then
            write (*,*) 'Iteration overflow, iter = ', ierr
         endif
      endif
      mter = nps
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPFZMOVE32(f,g,h,noff,nyzp,noffs,nyzps,noffd,nyzpd,    &
     &isign,kyp,kzp,ny,nz,kstrt,nvpy,nvpz,nxv,nypmx,nzpmx,idds,mter,ierr&
     &)
! this subroutine moves fields into appropriate spatial regions in z,
! between non-uniform and uniform partitions
! f(j,k,l) = real data for grid j,k,j in field partition.
! the grid is non-uniform and includes extra guard cells.
! output: f, g, h, ierr, and possibly mter
! g(j,k*l)/h(j,k*l) = scratch data for grid j,k,l in field partition.
! noff(1) = lowermost global gridpoint in y in particle partition
! noff(2) = backmost global gridpoint in z in particle partition
! nyzp(1:2) = number of primary (complete) gridpoints in y/z
! noffs/nyzps = source or scratch arrays for field partition
! noffd/nyzpd = destination or scratch arrays for field partition
! isign = -1, move from non-uniform (noff(2)/nyzp(2)) to uniform (kzp)
!    fields.
! isign = 1, move from uniform (kzp) to non-uniform (noff(2)/nyzp(2))
!    fields.    Procedure PPFYMOVE32 should be called first
! if isign = 0, the noffs(2)/nyzps(2) contains the source partition,
!    noffd(2)/nyzpd(2) contains the destination partition, and
!    noff(2)/nyzp(2), kzp are not used.  the partitions
!    noffs(2)/nyzps(2) and noffd(2)/nyzpd(2) are modified.
! kyp/kzp = number of complex grids in y/z in each uniform field
!    partition.
! ny/nz = global number of grids in y/z
! kstrt = starting data block number
! nvpy/nvpz = number of real or virtual processors in y/z
! nxv = first dimension of f, must be >= nx
! nypmx = maximum size of field partition, must be >= kyp+1
! idds = dimensionality of domain decomposition = 2
! mter = number of shifts required
! if mter = 0, then number of shifts is determined and returned
! ierr = (0,1) = (no,yes) error condition exists
      implicit none
      integer, intent(in) :: isign, kyp, kzp, ny, nz, kstrt, nvpy, nvpz
      integer, intent(in) :: nxv, nypmx, nzpmx, idds
      integer, intent(inout) :: mter, ierr
      real, dimension(nxv,nypmx,nzpmx), intent(inout) :: f
      real, dimension(nxv,nypmx*nzpmx) :: g, h
      integer, dimension(idds), intent(in) :: noff, nyzp
      integer, dimension(idds), intent(inout) :: noffs, nyzps
      integer, dimension(idds), intent(inout) :: noffd, nyzpd
! lgrp = current communicator
! mint = default datatype for integers
! mreal = default datatype for reals
! local data
      integer :: j, k, l, nbsize, js, ks, id, kyps, kzps, iter, npr, nps
      integer :: nter, koff, loff, kl, kr, ll, nzpmn, itermax
      integer, dimension(2) :: jsl, jsr, ibflg, iwork
      integer :: msid
      integer, dimension(lstat) :: istatus
! exit if certain flags are set
      if ((mter < 0).or.(nvpz==1)) return
! find processor id and offsets in y/z
! js/ks = processor co-ordinates in x/y => id = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      kyps = min(kyp,max(0,ny-kyp*js))
      kzps = min(kzp,max(0,nz-kzp*ks))
      id = js + nvpy*ks
      nbsize = nxv*nypmx*nzpmx
      nzpmn = nzpmx
      iter = 2
      itermax = 200
      ierr = 0
      loff = min(kzp*ks,nz)
! kl/kr = processor location for grid  point ny/nz
      kl = (ny - 1)/kyp
      kr = (nz - 1)/kzp
! move from non-uniform to uniform field in z
      if (isign < 0) then
! set partition parameters
         noffs(2) = noff(2)
         nyzps(1) = nyzp(1)
         nyzps(2) = nyzp(2)
         noffd(2) = loff
         nyzpd(2) = kzps
! extend partition to include ny+1 grid
! for non-uniform partition, append on last processor in y
         if (js==(nvpy-1)) nyzps(1) = nyzps(1) + 1
! extend partition to include nz+1 grid
! for non-uniform partition, append on last processor in z
         if (ks==(nvpz-1)) nyzps(2) = nyzps(2) + 1
! for uniform partition, append just after nz grid point
         if (ks==kr) nyzpd(2) = nyzpd(2) + 1
         if (ks > kr) noffd(2) = noffd(2) + 1
! move from uniform in z to non-uniform fields
      else if (isign > 0) then
! set partition parameters in z
         noffs(2) = loff
         nyzps(1) = nyzp(1)
         nyzps(2) = kzps
         noffd(2) = noff(2)
         nyzpd(2) = nyzp(2)
! extend partition to include ny+1 grid
! for non-uniform partition, append on last processor in y
         if (js==(nvpy-1)) nyzps(1) = nyzps(1) + 1
! extend partition to include nz+1 grid
! for non-uniform partition, append on last processor in z
         if (ks==(nvpz-1)) nyzpd(2) = nyzpd(2) + 1
! for uniform partition, append just after nz grid point
         if (ks==kr) nyzps(2) = nyzps(2) + 1
         if (ks > kr) noffs(2) = noffs(2) + 1
! move from non-uniform to non-uniform fields
      else
! extend partitions to include (ny+1,nz+1) grids
         if (js==(nvpy-1)) then
            nyzps(1) = nyzps(1) + 1
            nyzpd(1) = nyzpd(1) + 1
         endif
         if (ks==nvpz-1) then
            nyzps(2) = nyzps(2) + 1
            nyzpd(2) = nyzpd(2) + 1
         endif
      endif
! main iteration loop
! determine number of outgoing grids
   10 kl = noffd(2)
      kr = kl + nyzpd(2)
      jsl(1) = 0
      jsr(1) = 0
      do k = 1, nyzps(2)
         ll = k + noffs(2)
! fields going right
         if (ll > kr) then
            jsr(1) = jsr(1) + 1
! fields going left
         else if (ll <= kl) then
            jsl(1) = jsl(1) + 1
         endif
      enddo
! copy fields
      iter = iter + 1
      npr = 0
      nter = 0
!
! get fields from left
      kr = id + nvpy
      kl = id - nvpy
      jsl(2) = 0
      jsr(2) = 0
      nps = nxv*jsr(1)*nyzps(1)
      loff = min(nyzps(2)-jsr(1)+1,nzpmx) - 1
! buffer outgoing data
!$OMP PARALLEL DO PRIVATE(j,k,l,koff)
      do l = 1, jsr(1)
         koff = nyzps(1)*(l - 1)
         do k = 1, nyzps(1)
            do j = 1, nxv
               g(j,k+koff) = f(j,k,l+loff)
            enddo
         enddo
      enddo
!$OMP END PARALLEL DO
! this segment is used for mpi computers
! post receive from left
      if (ks > 0) then
         call MPI_IRECV(h,nbsize,mreal,kl,iter,lgrp,msid,ierr)
      endif
! send fields to right
      if (ks < (nvpz-1)) then
         call MPI_SEND(g,nps,mreal,kr,iter,lgrp,ierr)
      endif
! wait for fields to arrive
      if (ks > 0) then
         call MPI_WAIT(msid,istatus,ierr)
         call MPI_GET_COUNT(istatus,mreal,nps,ierr)
! assumes nyzps(1) is same for sender and receiver
         if (nps > 0) jsl(2) = nps/(nxv*nyzps(1))
      endif
! adjust field size
      nyzps(2) = nyzps(2) - jsr(1)
! do not allow move to overflow field array
      jsr(1) = max0((nyzps(2)+jsl(2)-nzpmn),0)
      if (jsr(1) > 0) then
         nyzps(2) = nyzps(2) - jsr(1)
         npr = max0(npr,jsr(1))
! save whatever is possible into end of g
         ll = min0(jsr(1),nzpmn-jsl(2))
!$OMP PARALLEL DO PRIVATE(j,k,l,koff)
         do l = 1, ll
            koff = nyzps(1)*(nzpmn-ll+l-1)
            do k = 1, nyzps(1)
              do j = 1, nxv
                  h(j,k+koff) = f(j,k,nyzps(2)+l)
               enddo
            enddo
         enddo
!$OMP END PARALLEL DO
      endif
! shift data which is staying, if necessary
      if ((nyzps(2) > 0).and.(jsl(2) > 0)) then
         do l = 1, nyzps(2)
           ll = nyzps(2) - l + 1
!$OMP PARALLEL DO PRIVATE(j,k)
           do k = 1, nyzps(1)
               do j = 1, nxv
                  f(j,k,ll+jsl(2)) = f(j,k,ll)
               enddo
            enddo
!$OMP END PARALLEL DO
         enddo
      endif
! insert data coming from left
!$OMP PARALLEL DO PRIVATE(j,k,l,koff)
      do l = 1, jsl(2)
         koff = nyzps(1)*(l - 1)
         do k = 1, nyzps(1)
            do j = 1, nxv
               f(j,k,l) = h(j,k+koff)
            enddo
         enddo
      enddo
!$OMP END PARALLEL DO
! adjust field size and offset
      nyzps(2) = nyzps(2) + jsl(2)
      noffs(2) = noffs(2) - jsl(2)
!
! get fields from right
      kr = id + nvpy
      kl = id - nvpy
      nps = nxv*jsl(1)*nyzps(1)
      iter = iter + 1
! buffer outgoing data
!$OMP PARALLEL DO PRIVATE(j,k,l,koff)
      do l = 1, jsl(1)
         koff = nyzps(1)*(l - 1)
         do k = 1, nyzps(1)
            do j = 1, nxv
               g(j,k+koff) = f(j,k,l)
            enddo
         enddo
      enddo
!$OMP END PARALLEL DO
! this segment is used for mpi computers
! post receive from right
      if (ks < (nvpz-1)) then
         call MPI_IRECV(h,nbsize,mreal,kr,iter,lgrp,msid,ierr)
      endif
! send fields to left
      if (ks > 0) then
         call MPI_SEND(g,nps,mreal,kl,iter,lgrp,ierr)
      endif
! wait for fields to arrive
      if (ks < (nvpz-1)) then
         call MPI_WAIT(msid,istatus,ierr)
         call MPI_GET_COUNT(istatus,mreal,nps,ierr)
! assumes nyzps(1) is same for sender and receiver
         if (nps > 0) jsr(2) = nps/(nxv*nyzps(1))
      endif
! adjust field size
      nyzps(2) = nyzps(2) - jsl(1)
      noffs(2) = noffs(2) + jsl(1)
! shift data which is staying, if necessary
      if ((nyzps(2) > 0).and.(jsl(1) > 0)) then
         do l = 1, nyzps(2)
!$OMP PARALLEL DO PRIVATE(j,k)
            do k = 1, nyzps(1)
               do j = 1, nxv
                  f(j,k,l) = f(j,k,l+jsl(1))
               enddo
           enddo
!$OMP END PARALLEL DO
        enddo
      endif
! do not allow move to overflow field array
      jsl(1) = max0((nyzps(2)+jsr(2)-nzpmn),0)
      if (jsl(1) > 0) then
         npr = max0(npr,jsl(1))
         jsr(2) = jsr(2) - jsl(1)
      endif
! process if no prior error
      if ((jsl(1) > 0).or.(jsr(1) <= 0)) then
! insert data coming from right
!$OMP PARALLEL DO PRIVATE(j,k,l,koff)
         do l = 1, jsr(2)
            koff = nyzps(1)*(l - 1)
            do k = 1, nyzps(1)
               do j = 1, nxv
                  f(j,k,l+nyzps(2)) = h(j,k+koff)
               enddo
            enddo
         enddo
!$OMP END PARALLEL DO
! adjust field size and offset
         nyzps(2) = nyzps(2) + jsr(2)
      endif
! check if desired partition is achieved
      if (nyzps(1) > 0) then
         nter = nter + abs(nyzps(2)-nyzpd(2)) + abs(noffs(2)-noffd(2))
      endif
! calculate number of iterations
      nps = iter/2 - 1
      if (nps <= mter) then
! process errors
! should not happen, other processors do not know about this error
         if (npr /= 0) then
            ierr = npr
            write (*,*) kstrt, 'local field overflow error, ierr=', ierr
            return
         endif
! continue iteration
         if (nps < mter) go to 10
         return
      endif
! check errors, executed only first time, when mter = 0
      ibflg(1) = npr
      ibflg(2) = nter
      call PPIMAX(ibflg,iwork,2)
! field overflow error
      if (ibflg(1) /= 0) then
         ierr = ibflg(1)
         if (kstrt==1) then
            write (*,*) 'global field overflow error, ierr = ', ierr
         endif
         return
      endif
! check if any fields have to be passed further
      if (ibflg(2) > 0) then
!        if (kstrt==1) then
!           write (2,*) 'Info: fields being passed further = ', ibflg(2)
!        endif
! continue iteration
         if (iter < itermax) go to 10
         ierr = -((iter-2)/2)
         if (kstrt==1) then
            write (*,*) 'Iteration overflow, iter = ', ierr
         endif
      endif
      mter = nps
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPTPOS3A(f,g,s,t,nx,ny,nz,kxyp,kyp,kzp,kstrt,nvpy,nxv, &
     &nyv,kxypd,kypd,kzpd)
! this subroutine performs a transpose of a matrix f, distributed in y
! and z to a matrix g, distributed in x and z, that is,
! g(k+kyp*(m-1),j,l) = f(j+kxyp*(n-1),k,l), where
! 1 <= j <= kxyp, 1 <= k <= kyp, 1 <= l <= kzp, and
! 1 <= n <= nx/kxyp, 1 <= m <= ny/kyp
! and where indices n and m can be distributed across processors.
! this subroutine sends and receives one message at a time, either
! synchronously or asynchronously. it uses a minimum of system resources
! f = complex input array
! g = complex output array
! s, t = complex scratch arrays
! nx/ny/nz = number of points in x/y/z
! kxyp/kyp/kzp = number of data values per block in x/y/z
! kstrt = starting data block number
! nvpy = number of real or virtual processors in y
! nxv/nyv = first dimension of f/g
! kypd/kxypd = second dimension of f/g
! kzpd = third dimension of f and g
      implicit none
      integer, intent(in) :: nx, ny, nz, kxyp, kyp, kzp, kstrt, nvpy
      integer, intent(in) :: nxv, nyv, kxypd, kypd, kzpd
      complex, dimension(nxv,kypd,kzpd), intent(in) :: f
      complex, dimension(nyv,kxypd,kzpd), intent(inout) :: g
      complex, dimension(kxyp*kyp*kzp), intent(inout) :: s, t
! lgrp = current communicator
! mcplx = default datatype for complex
! local data
      integer :: n, j, k, l, js, ks, kxyps, kyps, kzps, id, joff, koff
      integer :: ld, jd, kxyzp
      integer :: ierr, msid, ll
      integer, dimension(lstat) :: istatus
! js/ks = processor co-ordinates in y/z => idproc = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      kxyps = min(kxyp,max(0,nx-kxyp*js))
      kyps = min(kyp,max(0,ny-kyp*js))
      kzps = min(kzp,max(0,nz-kzp*ks))
      kxyzp = kxyp*kyp*kzp
! special case for one processor
      if (nvpy==1) then
!$OMP PARALLEL DO PRIVATE(j,k,l,ll)
         do ll = 1, kyp*kzp
            l = (ll - 1)/kyp
            k = ll - kyp*l
            l = l + 1
            do j = 1, kxyp
               g(k,j,l) = f(j,k,l)
            enddo
         enddo
!$OMP END PARALLEL DO
         return
      endif
! this segment is used for shared memory computers
!     do l = 1, nz
!        do m = 1, min(ny,nvpy)
!           koff = kyp*(m - 1)
!           do i = 1, min(nx,nvpy)
!           joff = kxyp*(i - 1)
!              do k = 1, min(kyp,max(0,ny-koff))
!                 do j = 1, min(kxyp,max(0,nx-joff))
!                    g(k+koff,j+joff,l) = f(j+joff,k+koff,l)
!                 enddo
!              enddo
!           enddo
!        enddo
!     enddo
! this segment is used for mpi computers
      do n = 1, nvpy
         id = n - js - 1
         if (id < 0) id = id + nvpy
! extract data to send
         joff = kxyp*id
         ld = min(kxyp,max(0,nx-joff))
!$OMP PARALLEL DO PRIVATE(j,k,l,ll,koff)
         do ll = 1, kyps*kzps
            l = (ll - 1)/kyps
            k = ll - kyps*l
            l = l + 1
            koff = kyps*(l - 1) - 1
            do j = 1, ld
               s(j+ld*(k+koff)) = f(j+joff,k,l)
            enddo
         enddo
!$OMP END PARALLEL DO
         jd = id + nvpy*ks
         ld = ld*kyps*kzps
! post receive
         call MPI_IRECV(t,kxyzp,mcplx,jd,n,lgrp,msid,ierr)
! send data
         call MPI_SEND(s,ld,mcplx,jd,n,lgrp,ierr)
! receive data
         call MPI_WAIT(msid,istatus,ierr)
! insert data received
         koff = kyp*id
         ld = min(kyp,max(0,ny-koff))
!$OMP PARALLEL DO PRIVATE(j,k,l,ll,joff)
         do ll = 1, ld*kzps
            l = (ll - 1)/ld
            k = ll - ld*l
            l = l + 1
            joff = ld*(l - 1) - 1
            do j = 1, kxyps
               g(k+koff,j,l) = t(j+kxyps*(k+joff))
            enddo
         enddo
!$OMP END PARALLEL DO
      enddo
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPTPOS3B(g,h,s,t,nx,ny,nz,kxyp,kyzp,kzp,kstrt,nvpy,nvpz&
     &,nyv,nzv,kxypd,kyzpd,kzpd)
! this subroutine performs a transpose of a matrix g, distributed in x
! and z to a matrix h, distributed in x and y, that is,
! h(l+kzp*(n-1),j,k) = g(k+kyzp*(m-1),j,l), where
! 1 <= j <= kxyp, 1 <= k <= kyzp, 1 <= l <= kzp, and
! 1 <= m <= ny/kyzp, 1 <= n <= nz/kzp
! and where indices n and m can be distributed across processors.
! this subroutine sends and receives one message at a time, either
! synchronously or asynchronously. it uses a minimum of system resources
! g = complex input array
! h = complex output array
! s, t = complex scratch arrays
! nx/ny/nz = number of points in x/y/z
! kxyp/kyzp/kzp = number of data values per block in x/y/z
! kstrt = starting data block number
! nvpy/nvpz = number of real or virtual processors in y/z
! nyv/nzv = first dimension of g/h
! kxypd = second dimension of g and h
! kzpd/kyzpd = third dimension of g/h
      implicit none
      integer, intent(in) :: nx, ny, nz, kxyp, kyzp, kzp, kstrt
      integer, intent(in) :: nvpy, nvpz, nyv, nzv, kxypd, kyzpd, kzpd
      complex, dimension(nyv,kxypd,kzpd), intent(inout) :: g
      complex, dimension(nzv,kxypd,kyzpd), intent(inout) :: h
      complex, dimension(kyzp*kxyp*kzp), intent(inout) :: s, t
! lgrp = current communicator
! mcplx = default datatype for complex
! local data
      integer :: n, j, k, l, js, ks, kxyps, kyzps, kzps, id, koff, loff
      integer :: ld, jd, kxyzp, ll
      integer :: ierr, msid
      integer, dimension(lstat) :: istatus
! js/ks = processor co-ordinates in x/z => idproc = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      kxyps = min(kxyp,max(0,nx-kxyp*js))
      kyzps = min(kyzp,max(0,ny-kyzp*ks))
      kzps = min(kzp,max(0,nz-kzp*ks))
      kxyzp = kxyp*kyzp*kzp
! special case for one processor
      if (nvpz==1) then
!$OMP PARALLEL DO PRIVATE(j,k,l,ll)
         do ll = 1, kxyp*kzp
            l = (ll - 1)/kxyp
            j = ll - kxyp*l
            l = l + 1
            do k = 1, kyzp
               h(l,j,k) = g(k,j,l)
            enddo
         enddo
!$OMP END PARALLEL DO
         return
      endif
! this segment is used for shared memory computers
!     do i = 1, min(nz,nvpz)
!        loff = kzp*(i - 1)
!        do m = 1, min(ny,nvpz)
!           koff = kyzp*(m - 1)
!           do l = 1, min(kzp,max(0,nz-loff))
!              do j = 1, nx
!                 do k = 1, min(kyzp,max(0,ny-koff))
!                    h(l+loff,j,k+koff) = g(k+koff,j,l+loff)
!                 enddo
!              enddo
!           enddo
!        enddo
!     enddo
! this segment is used for mpi computers
      do n = 1, nvpz
         id = n - ks - 1
         if (id < 0) id = id + nvpz
! extract data to send
         koff = kyzp*id
         ld = min(kyzp,max(0,ny-koff))
!$OMP PARALLEL DO PRIVATE(j,k,l,ll,loff)
         do ll = 1, kxyps*kzps
            l = (ll - 1)/kxyps
            j = ll - kxyps*l
            l = l + 1
            loff = kxyps*(l - 1) - 1
            do k = 1, ld
               s(k+ld*(j+loff)) = g(k+koff,j,l)
            enddo
         enddo
!$OMP END PARALLEL DO
         jd = js + nvpy*id
         ld = ld*kxyps*kzps
! post receive
         call MPI_IRECV(t,kxyzp,mcplx,jd,n,lgrp,msid,ierr)
! send data
         call MPI_SEND(s,ld,mcplx,jd,n,lgrp,ierr)
! receive data
         call MPI_WAIT(msid,istatus,ierr)
! insert data received
         loff = kzp*id
         ld = min(kzp,max(0,nz-loff))
!$OMP PARALLEL DO PRIVATE(j,k,l,ll,koff)
         do ll = 1, kxyps*ld
            l = (ll - 1)/kxyps
            j = ll - kxyps*l
            l = l + 1
            koff = kxyps*(l - 1) - 1
            do k = 1, kyzps
               h(l+loff,j,k) = t(k+kyzps*(j+koff))
            enddo
         enddo
!$OMP END PARALLEL DO
      enddo
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPNTPOS3A(f,g,s,t,nx,ny,nz,kxyp,kyp,kzp,kstrt,nvpy,ndim&
     &,nxv,nyv,kxypd,kypd,kzpd)
! this subroutine performs a transpose of a matrix f, distributed in y
! and z to a matrix g, distributed in x and z, that is,
! g(1:ndim,k+kyp*(m-1),j,l) = f(1:ndim,j+kxyp*(n-1),k,l), where
! 1 <= j <= kxyp, 1 <= k <= kyp, 1 <= l <= kzp, and
! 1 <= n <= nx/kxyp, 1 <= m <= ny/kyp
! and where indices n and m can be distributed across processors.
! this subroutine sends and receives one message at a time, either
! synchronously or asynchronously. it uses a minimum of system resources
! f = complex input array
! g = complex output array
! s, t = complex scratch arrays
! nx/ny/nz = number of points in x/y/z
! kxyp/kyp/kzp = number of data values per block in x/y/z
! kstrt = starting data block number
! nvpy = number of real or virtual processors in y
! ndim = leading dimension of arrays f and g
! nxv/nyv = first dimension of f/g
! kypd/kxypd = second dimension of f/g
! kzpd = third dimension of f and g
      implicit none
      integer, intent(in) :: nx, ny, nz, kxyp, kyp, kzp, kstrt, nvpy
      integer, intent(in) :: ndim, nxv, nyv, kxypd, kypd, kzpd
      complex, dimension(ndim,nxv,kypd,kzpd), intent(in) :: f
      complex, dimension(ndim,nyv,kxypd,kzpd), intent(inout) :: g
      complex, dimension(ndim,kxyp*kyp*kzp), intent(inout) :: s, t
! lgrp = current communicator
! mcplx = default datatype for complex
! local data
      integer :: i, n, j, k, l, js, ks, kxyps, kyps, kzps, id
      integer :: joff, koff, ld, jd, kxyzp, ll
      integer :: ierr, msid
      integer, dimension(lstat) :: istatus
! js/ks = processor co-ordinates in y/z => idproc = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      kxyps = min(kxyp,max(0,nx-kxyp*js))
      kyps = min(kyp,max(0,ny-kyp*js))
      kzps = min(kzp,max(0,nz-kzp*ks))
      kxyzp = ndim*kxyp*kyp*kzp
! special case for one processor
      if (nvpy==1) then
!$OMP PARALLEL DO PRIVATE(i,j,k,l,ll)
         do ll = 1, kyp*kzp
            l = (ll - 1)/kyp
            k = ll - kyp*l
            l = l + 1
            do j = 1, kxyp
               do i = 1, ndim
                  g(i,k,j,l) = f(i,j,k,l)
               enddo
            enddo
         enddo
!$OMP END PARALLEL DO
         return
      endif
! this segment is used for shared memory computers
!     do l = 1, nz
!        do m = 1, min(ny,nvpy)
!           koff = kyp*(m - 1)
!           do i = 1, min(nx,nvpy)
!              joff = kxyp*(i - 1)
!              do k = 1, min(kyp,max(0,ny-koff))
!                 do j = 1, min(kxyp,max(0,nx-joff))
!                    do n = 1, ndim
!                       g(n,k+koff,j+joff,l) = f(n,j+joff,k+koff,l)
!                    enddo
!                 enddo
!              enddo
!           enddo
!        enddo
!     enddo
! this segment is used for mpi computers
      do n = 1, nvpy
         id = n - js - 1
         if (id < 0) id = id + nvpy
! extract data to send
         joff = kxyp*id
         ld = min(kxyp,max(0,nx-joff))
!$OMP PARALLEL DO PRIVATE(i,j,k,l,ll,koff)
         do ll = 1, kyps*kzps
            l = (ll - 1)/kyps
            k = ll - kyps*l
            l = l + 1
            koff = kyps*(l - 1) - 1
            do j = 1, ld
               do i = 1, ndim
                  s(i,j+ld*(k+koff)) = f(i,j+joff,k,l)
               enddo
            enddo
         enddo
!$OMP END PARALLEL DO
         jd = id + nvpy*ks
         ld = ndim*ld*kyps*kzps
! post receive
         call MPI_IRECV(t,kxyzp,mcplx,jd,n,lgrp,msid,ierr)
! send data
         call MPI_SEND(s,ld,mcplx,jd,n,lgrp,ierr)
! receive data
         call MPI_WAIT(msid,istatus,ierr)
! insert data received
         koff = kyp*id
         ld = min(kyp,max(0,ny-koff))
!$OMP PARALLEL DO PRIVATE(i,j,k,l,ll,joff)
         do ll = 1, ld*kzps
            l = (ll - 1)/ld
            k = ll - ld*l
            l = l + 1
            joff = ld*(l - 1) - 1
            do j = 1, kxyps
               do i = 1, ndim
                  g(i,k+koff,j,l) = t(i,j+kxyps*(k+joff))
               enddo
            enddo
         enddo
!$OMP END PARALLEL DO
      enddo
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPNTPOS3B(g,h,s,t,nx,ny,nz,kxyp,kyzp,kzp,kstrt,nvpy,   &
     &nvpz,ndim,nyv,nzv,kxypd,kyzpd,kzpd)
! this subroutine performs a transpose of a matrix g, distributed in x
! and z to a matrix h, distributed in x and y, that is,
! h(1:ndim,l+kzp*(n-1),j,k) = g(1:ndim,k+kyzp*(m-1),j,l), where
! 1 <= j <= kxyp, 1 <= k <= kyzp, 1 <= l <= kzp, and
! 1 <= m <= ny/kyzp, 1 <= n <= nz/kzp
! and where indices n and m can be distributed across processors.
! this subroutine sends and receives one message at a time, either
! synchronously or asynchronously. it uses a minimum of system resources
! g = complex input array
! h = complex output array
! s, t = complex scratch arrays
! nx/ny/nz = number of points in x/y/z
! kxyp/kyzp/kzp = number of data values per block in x/y/z
! kstrt = starting data block number
! nvpy/nvpz = number of real or virtual processors in y/z
! ndim = leading dimension of arrays g and h
! nyv/nzv = first dimension of g/h
! kxypd = second dimension of g and h
! kzpd/kyzpd = third dimension of g/h
      implicit none
      integer, intent(in) :: nx, ny, nz, kxyp, kyzp, kzp, kstrt, nvpy
      integer, intent(in) :: nvpz, ndim, nyv, nzv, kxypd, kyzpd, kzpd
      complex, dimension(ndim,nyv,kxypd,kzpd), intent(inout) :: g
      complex, dimension(ndim,nzv,kxypd,kyzpd), intent(inout) :: h
      complex, dimension(ndim,kyzp*kxyp*kzp), intent(inout) :: s, t
! lgrp = current communicator
! mcplx = default datatype for complex
! local data
      integer :: i, n, j, k, l, js, ks, kxyps, kyzps, kzps, id
      integer :: koff, loff, ld, jd, kxyzp, ll
      integer :: ierr, msid
      integer, dimension(lstat) :: istatus
! js/ks = processor co-ordinates in x/z => idproc = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      kxyps = min(kxyp,max(0,nx-kxyp*js))
      kyzps = min(kyzp,max(0,ny-kyzp*ks))
      kzps = min(kzp,max(0,nz-kzp*ks))
      kxyzp = ndim*kxyp*kyzp*kzp
! special case for one processor
      if (nvpz==1) then
!$OMP PARALLEL DO PRIVATE(i,j,k,l,ll)
         do ll = 1, kxyp*kzp
            l = (ll - 1)/kxyp
            j = ll - kxyp*l
            l = l + 1
            do k = 1, kyzp
               do i = 1, ndim
                  h(i,l,j,k) = g(i,k,j,l)
               enddo
            enddo
         enddo
!$OMP END PARALLEL DO
         return
      endif
! this segment is used for shared memory computers
!     do i = 1, min(nz,nvpz)
!        loff = kzp*(i - 1)
!        do m = 1, min(ny,nvpz)
!           koff = kyzp*(m - 1)
!           do l = 1, min(kzp,max(0,nz-loff))
!              do j = 1, nx
!                 do k = 1, min(kyzp,max(0,ny-koff))
!                    do n = 1, ndim
!                       h(n,l+loff,j,k+koff) = g(n,k+koff,j,l+loff)
!                    enddo
!                 enddo
!              enddo
!           enddo
!        enddo
!     enddo
! this segment is used for mpi computers
      do n = 1, nvpz
         id = n - ks - 1
         if (id < 0) id = id + nvpz
! extract data to send
         koff = kyzp*id
         ld = min(kyzp,max(0,ny-koff))
!$OMP PARALLEL DO PRIVATE(i,j,k,l,ll,loff)
         do ll = 1, kxyps*kzps
            l = (ll - 1)/kxyps
            j = ll - kxyps*l
            l = l + 1
            loff = kxyps*(l - 1) - 1
            do k = 1, ld
               do i = 1, ndim
                  s(i,k+ld*(j+loff)) = g(i,k+koff,j,l)
               enddo
            enddo
         enddo
!$OMP END PARALLEL DO
         jd = js + nvpy*id
         ld = ndim*ld*kxyps*kzps
! post receive
         call MPI_IRECV(t,kxyzp,mcplx,jd,n,lgrp,msid,ierr)
! send data
         call MPI_SEND(s,ld,mcplx,jd,n,lgrp,ierr)
! receive data
         call MPI_WAIT(msid,istatus,ierr)
! insert data received
         loff = kzp*id
         ld = min(kzp,max(0,nz-loff))
!$OMP PARALLEL DO PRIVATE(i,j,k,l,ll,koff)
         do ll = 1, kxyps*ld
            l = (ll - 1)/kxyps
            j = ll - kxyps*l
            l = l + 1
            koff = kxyps*(l - 1) - 1
            do k = 1, kyzps
               do i = 1, ndim
                  h(i,l+loff,j,k) = t(i,k+kyzps*(j+koff))
               enddo
            enddo
         enddo
!$OMP END PARALLEL DO
      enddo
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPMOVE32(part,edges,npp,sbufr,sbufl,rbufr,rbufl,ihole, &
     &ny,nz,kstrt,nvpy,nvpz,nc,idimp,npmax,idps,nbmax,ntmax,info)
! this subroutine moves particles into appropriate spatial regions
! ihole array is calculated in particle push procedure
! with periodic boundary conditions and 2D spatial decomposition
! output: part, ihole, npp, sbufr, sbufl, rbufr, rbufl, info
! part(1,n) = position x of particle n in partition
! part(2,n) = position y of particle n in partition
! part(3,n) = position z of particle n in partition
! part(4,n) = velocity vx of particle n in partition
! part(5,n) = velocity vy of particle n in partition
! part(6,n) = velocity vz of particle n in partition m
! edges(1:2) = lower/upper boundary in y of particle partition
! edges(3:4) = back/front boundary in z of particle partition
! npp = number of particles in partition
! sbufl = buffer for particles being sent to back processor
! sbufr = buffer for particles being sent to front processor
! rbufl = buffer for particles being received from back processor
! rbufr = buffer for particles being received from front processor
! ihole = location of holes left in particle arrays
! ny/nz = system length in y/z direction
! kstrt = starting data block number
! nvpy/nvpz = number of real or virtual processors in y/z
! nc = (1,2) = (normal,tagged) partitioned co-ordinate to sort by
! idimp = size of phase space = 6
! npmax = maximum number of particles in each partition.
! idps = number of particle partition boundaries = 4
! nbmax =  size of buffers for passing particles between processors
! ntmax =  size of hole array for particles leaving processors
! info = status information
! info(1) = ierr = (0,N) = (no,yes) error condition exists
! info(2) = maximum number of particles per processor
! info(3) = minimum number of particles per processor
! info(4:5) = maximum number of buffer overflows in y/z
! info(6:7) = maximum number of particle passes required in y/z
      implicit none
      integer, intent(in) :: ny, nz, kstrt, nvpy, nvpz, nc, idimp, npmax
      integer, intent(in) :: idps, nbmax, ntmax
      integer, intent(inout) :: npp
      real, dimension(idimp,npmax), intent(inout) :: part
      real, dimension(idps), intent(in) :: edges
      real, dimension(idimp,nbmax), intent(inout) :: sbufr, sbufl
      real, dimension(idimp,nbmax), intent(inout) :: rbufr, rbufl
      integer, dimension(ntmax+1,2) , intent(inout):: ihole
      integer, dimension(7), intent(inout) :: info
! lgrp = current communicator
! mint = default datatype for integers
! mreal = default datatype for reals
! local data
! iy/iz = partitioned co-ordinates
!     integer, parameter :: iy = 2, iz = 3
      integer :: i, j, n, js, ks, ic, nvp, iter, nps, kl, kr, j1, j2
      integer :: ih, jh, nh, j3, joff, jin, nbsize, nter, mter, itermax
      integer :: itg, iy, iz, ierr
      real :: an, xt
      integer, dimension(4) :: msid
      integer, dimension(lstat) :: istatus
      integer, dimension(2) :: kb, jsl, jsr, jss
      integer, dimension(5) :: ibflg, iwork
      if ((nc.lt.1).or.(nc.gt.2)) return
! determine co-ordinate to sort by
      if (nc.eq.1) then
         iy = 2
         iz = 3
      else if (idimp.gt.6) then
         iy = 7
         iz = 7
      else
         return
      endif
! js/ks = processor co-ordinates in y/z=> idproc = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      nbsize = idimp*nbmax
      info(1) = 0
      info(6) = 0
      info(7) = 0
      itermax = 2000
! buffer outgoing particles, first in y then in z direction
         do n = 1, 2
         if (n==1) then
            ic = iy
            nvp = nvpy
            an = real(ny)
            jh = ihole(1,n+1)
            ibflg(5) = 0
         else if (n==2) then
            ic = iz
            nvp = nvpz
            an = real(nz)
         endif
         iter = 2
         nter = 0
         ih = ihole(1,n)
         joff = 1
         jin = 1
! ih = number of particles extracted from holes
! joff = next hole location for extraction
! jss(1) = number of holes available to be filled
! jin = next hole location to be filled
! start loop
   10    mter = 0
         nps = 0
         kb(1) = js
         kb(2) = ks
! buffer outgoing particles
         jsl(1) = 0
         jsr(1) = 0
! load particle buffers
         do j = 1, ih
            j1 = ihole(j+joff,n)
            xt = part(ic,j1)
! particles going down or backward
            if (xt < edges(2*n-1)) then
               if (kb(n)==0) xt = xt + an
               if (jsl(1) < nbmax) then
                  jsl(1) = jsl(1) + 1
                  do i = 1, idimp
                     sbufl(i,jsl(1)) = part(i,j1)
                  enddo
                  sbufl(ic,jsl(1)) = xt
               else
                  nps = 1
                  exit
               endif
! particles going up or forward
            else
               if (kb(n)==(nvp-1)) xt = xt - an
               if (jsr(1) < nbmax) then
                  jsr(1) = jsr(1) + 1
                  do i = 1, idimp
                     sbufr(i,jsr(1)) = part(i,j1)
                  enddo
                  sbufr(ic,jsr(1)) = xt
               else
                  nps = 1
                  exit
               endif
            endif
         enddo
         jss(1) = jsl(1) + jsr(1)
         joff = joff + jss(1)
         ih = ih - jss(1)
! check for full buffer condition
         ibflg(3) = nps
! copy particle buffers
   60    iter = iter + 2
         mter = mter + 1
! special case for one processor
         if (nvp==1) then
            jsl(2) = jsr(1)
            do j = 1, jsl(2)
               do i = 1, idimp
                  rbufl(i,j) = sbufr(i,j)
               enddo
            enddo
            jsr(2) = jsl(1)
            do j = 1, jsr(2)
               do i = 1, idimp
                  rbufr(i,j) = sbufl(i,j)
               enddo
            enddo
! this segment is used for mpi computers
         else
! get particles from below and above or back and front
            kb(1) = js
            kb(2) = ks
            kl = kb(n)
            kb(n) = kl + 1
            if (kb(n) >= nvp) kb(n) = kb(n) - nvp
            kr = kb(1) + nvpy*kb(2)
            kb(n) = kl - 1
            if (kb(n) < 0) kb(n) = kb(n) + nvp
            kl = kb(1) + nvpy*kb(2)
! post receive
            itg = iter - 1
            call MPI_IRECV(rbufl,nbsize,mreal,kl,itg,lgrp,msid(1),ierr)
            call MPI_IRECV(rbufr,nbsize,mreal,kr,iter,lgrp,msid(2),ierr)
! send particles
            jsr(1) = idimp*jsr(1)
            call MPI_ISEND(sbufr,jsr(1),mreal,kr,itg,lgrp,msid(3),ierr)
            jsl(1) = idimp*jsl(1)
            call MPI_ISEND(sbufl,jsl(1),mreal,kl,iter,lgrp,msid(4),ierr)
! wait for particles to arrive
            call MPI_WAIT(msid(1),istatus,ierr)
            call MPI_GET_COUNT(istatus,mreal,nps,ierr)
            jsl(2) = nps/idimp
            call MPI_WAIT(msid(2),istatus,ierr)
            call MPI_GET_COUNT(istatus,mreal,nps,ierr)
            jsr(2) = nps/idimp
         endif
! check if particles must be passed further
! check if any particles coming from above or front belong here
         jsl(1) = 0
         jsr(1) = 0
         jss(2) = 0
         do j = 1, jsr(2)
            if (rbufr(ic,j) < edges(2*n-1)) jsl(1) = jsl(1) + 1
            if (rbufr(ic,j) >= edges(2*n)) jsr(1) = jsr(1) + 1
         enddo
!        if (jsr(1) /= 0) then
!           if (n==1) then
!              write (2,*) kb+1,'Info: particles returning above'
!           else if (n==2) then
!              write (2,*) kb+1,'Info: particles returning front'
!           endif
!       endif
! check if any particles coming from below or back belong here
         do j = 1, jsl(2)
            if (rbufl(ic,j) >= edges(2*n)) jsr(1) = jsr(1) + 1
            if (rbufl(ic,j) < edges(2*n-1)) jss(2) = jss(2) + 1
         enddo
!        if (jss(2) /= 0) then
!           if (n==1) then
!              write (2,*) kb+1,'Info: particles returning below'
!           else if (n==2) then
!              write (2,*) kb+1,'Info: particles returning back'
!           endif
!        endif
         nps = jsl(1) + jsr(1) + jss(2)
         ibflg(2) = nps
! make sure sbufr and sbufl have been sent
         if (nvp /= 1) then
            call MPI_WAIT(msid(3),istatus,ierr)
            call MPI_WAIT(msid(4),istatus,ierr)
         endif
         if (nps==0) go to 180
! remove particles which do not belong here
         kb(1) = js
         kb(2) = ks
! first check particles coming from above or front
         jsl(1) = 0
         jsr(1) = 0
         jss(2) = 0
         do j = 1, jsr(2)
            xt = rbufr(ic,j)
! particles going down or back
            if (xt < edges(2*n-1)) then
               jsl(1) = jsl(1) + 1
               if (kb(n)==0) xt = xt + an
               rbufr(ic,j) = xt
               do i = 1, idimp
                  sbufl(i,jsl(1)) = rbufr(i,j)
               enddo
! particles going up or front, should not happen
            else if (xt >= edges(2*n)) then
               jsr(1) = jsr(1) + 1
               if (kb(n)==(nvp-1)) xt = xt - an
               rbufr(ic,j) = xt
               do i = 1, idimp
                  sbufr(i,jsr(1)) = rbufr(i,j)
               enddo
! particles staying here
            else
               jss(2) = jss(2) + 1
               do i = 1, idimp
                  rbufr(i,jss(2)) = rbufr(i,j)
               enddo
            endif
         enddo
         jsr(2) = jss(2)
! next check particles coming from below or back
         jss(2) = 0
         do j = 1, jsl(2)
            xt = rbufl(ic,j)
! particles going up or front
            if (xt >= edges(2*n)) then
               if (jsr(1) < nbmax) then
                  jsr(1) = jsr(1) + 1
                  if (kb(n)==(nvp-1)) xt = xt - an
                  rbufl(ic,j) = xt
                  do i = 1, idimp
                     sbufr(i,jsr(1)) = rbufl(i,j)
                  enddo
               else
                  jss(2) = 2*npmax
                  exit
               endif
! particles going down or back, should not happen
            else if (xt < edges(2*n-1)) then
               if (jsl(1) < nbmax) then
                  jsl(1) = jsl(1) + 1
                  if (kb(n)==0) xt = xt + an
                  rbufl(ic,j) = xt
                  do i = 1, idimp
                     sbufl(i,jsl(1)) = rbufl(i,j)
                  enddo
               else
                  jss(2) = 2*npmax
                  exit
               endif
! particles staying here
            else
               jss(2) = jss(2) + 1
               do i = 1, idimp
                  rbufl(i,jss(2)) = rbufl(i,j)
               enddo
            endif
         enddo
         jsl(2) = jss(2)
! check if move would overflow particle array
  180    nps = npp + jsl(2) + jsr(2) - jss(1)
         ibflg(1) = nps
         ibflg(4) = -min0(npmax,nps)
         call PPIMAX(ibflg,iwork,5)
         info(2) = ibflg(1)
         info(3) = -ibflg(4)
         ierr = ibflg(1)
         if (ierr > npmax) then
!           write (2,*) 'particle overflow error, ierr = ', ierr
            info(1) = ierr
            return
         endif
! check for ihole overflow condition
         ierr = ibflg(5)
         if (ierr > ntmax) then
!           write (2,*) 'ihole overflow error, ierr = ', ierr
            info(1) = -ierr
            return
         endif
! distribute incoming particles from buffers
         nh = 0
! distribute particles coming from below or back into holes
         jss(2) = min0(jss(1),jsl(2))
         do j = 1, jss(2)
            j1 = ihole(j+jin,n)
            do i = 1, idimp
               part(i,j1) = rbufl(i,j)
            enddo
! check if incoming particle is also out of bounds in z
            if (n==1) then
               xt = part(iz,j1)
! if so, add it to list of particles in z
               if ((xt < edges(2*n+1)).or.(xt >= edges(2*n+2))) then
                  jh = jh + 1
                  if (jh <= ntmax) then
                     ihole(jh+1,n+1) = j1
                  else
                     nh = 1
                 endif
               endif
            endif
         enddo
         jin = jin + jss(2)
         if (jss(1) > jsl(2)) then
            jss(2) = min0(jss(1)-jsl(2),jsr(2))
         else
            jss(2) = jsl(2) - jss(1)
         endif
         do j = 1, jss(2)
! no more particles coming from below or back
! distribute particles coming from above or front into holes
            if (jss(1) > jsl(2)) then
               j1 = ihole(j+jin,n)
               do i = 1, idimp
                  part(i,j1) = rbufr(i,j)
               enddo
! check if incoming particle is also out of bounds in z
               if (n==1) then
                  xt = part(iz,j1)
! if so, add it to list of particles in z
                  if ((xt < edges(2*n+1)).or.(xt >= edges(2*n+2))) then
                     jh = jh + 1
                     if (jh <= ntmax) then
                        ihole(jh+1,n+1) = j1
                     else
                        nh = 1
                     endif
                  endif
             endif
! no more holes
! distribute remaining particles from below or back into bottom
            else
               do i = 1, idimp
                  part(i,j+npp) = rbufl(i,j+jss(1))
               enddo
! check if incoming particle is also out of bounds in z
               if (n==1) then
                  xt = part(iz,j+npp)
! if so, add it to list of particles in z
                  if ((xt < edges(2*n+1)).or.(xt >= edges(2*n+2))) then
                     jh = jh + 1
                     if (jh <= ntmax) then
                        ihole(jh+1,n+1) = j + npp
                     else
                        nh = 1
                     endif
                  endif
               endif
            endif
         enddo
         if (jss(1) > jsl(2)) jin = jin + jss(2)
         nps = jsl(2) + jsr(2)
         if (jss(1) <= jsl(2)) then
            npp = npp + (jsl(2) - jss(1))
            jss(1) = jsl(2)
         endif
! no more holes
! distribute remaining particles from above into bottom
         jsr(2) = max0(0,nps-jss(1))
         jss(1) = jss(1) - jsl(2)
         do j = 1, jsr(2)
            do i = 1, idimp
               part(i,j+npp) = rbufr(i,j+jss(1))
            enddo
! check if incoming particle is also out of bounds in z
            if (n==1) then
               xt = part(iz,j+npp)
! if so, add it to list of particles in z
               if ((xt < edges(2*n+1)).or.(xt >= edges(2*n+2))) then
                  jh = jh + 1
                  if (jh <= ntmax) then
                     ihole(jh+1,n+1) = j + npp
                  else
                     nh = 1
                  endif
               endif
            endif

         enddo
         npp = npp + jsr(2)
! check for ihole overflow condition
         if ((n==1).and.(nh > 0)) ibflg(5) = jh
! holes left over
! fill up remaining holes in particle array with particles from bottom
         if (ih==0) then
            jsr(2) = max0(0,ihole(1,n)-jin+1)
            nh = 0
! holes are stored in increasing value
            if (n==1) then
               do j = 1, jsr(2)
                  j1 = npp - j + 1
                  j2 = ihole(jsr(2)-j+jin+1,n)
                  if (j1 > j2) then
! move particle only if it is below current hole
                     do i = 1, idimp
                        part(i,j2) = part(i,j1)
                     enddo
! check if this move makes the ihole list for z invalid
                     xt = part(iz,j1)
                     if ((xt<edges(2*n+1)).or.(xt>=edges(2*n+2))) then
                        i = jh + 1
! if so, adjust the list of holes
                        j3 = ihole(i,n+1)
                        do while (j3 /= j1)
                           i = i - 1
                           if (i==1) then
                              write (*,*) kstrt,                        &
     &                        'cannot find particle:n,j1=', n, j1
                              nh = 1
                              exit
                           endif
                           j3 = ihole(i,n+1)
                        enddo
! update ihole list to use new location
                        ihole(i,n+1) = j2
                     endif
                  endif
               enddo
! holes may not be stored in increasing value
            else
               do j = 1, jsr(2)
                  j1 = npp - j + 1
                  j2 = ihole(jsr(2)-j+jin+1,n)
                  xt = part(iz,j1)
! determine if particle at location j1 represents an unfilled hole
                  if ((xt < edges(2*n-1)).or.(xt >= edges(2*n))) then
                     i = jh + 2 - j
! if so, adjust the list of holes
                     j3 = ihole(i,n)
                     do while (j3 /= j1)
                        i = i - 1
                        if (i==1) then
                           write (*,*) kstrt,                           &
     &                     'cannot find particle:n,j1=', n, j1
                           nh = 1
                           exit
                        endif
                        j3 = ihole(i,n)
                     enddo
! update ihole list to use new location
                     ihole(i,n) = j2
                  else if (j1 > j2) then
! move particle only if it is below current hole
                     do i = 1, idimp
                        part(i,j2) = part(i,j1)
                     enddo
                  endif
               enddo
! check for lost particle error
               if (nh > 0) call PPABORT
            endif
            jin = jin + jsr(2)
            npp = npp - jsr(2)
         endif
         jss(1) = 0
! check if any particles have to be passed further
         if (ibflg(3) > 0) ibflg(3) = 1
         info(5+n) = max0(info(5+n),mter)
         if (ibflg(2) > 0) then
!           write (2,*) 'Info: particles being passed further = ',      &
!    &                   ibflg(2)
            if (iter < itermax) go to 60
            ierr = -((iter-2)/2)
            if (kstrt==1) then
               write (*,*) 'Iteration overflow, iter = ', ierr
            endif
            info(1) = ierr
            return
         endif
! check if buffer overflowed and more particles remain to be checked
         if (ibflg(3) > 0) then
            nter = nter + 1
            go to 10
         endif
         info(3+n) = nter
!        if (nter > 0) then
!           if (kstrt==1) then
!              write (2,*) 'Info: ',nter,' buffer overflows, nbmax=',   &
!    &                     nbmax
!           endif
!        endif
! update ihole number in z
         if (n==1) ihole(1,2) = jh
      enddo
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPPMOVE32(sbufr,sbufl,rbufr,rbufl,ncll,nclr,mcll,mclr, &
     &mcls,kstrt,nvpy,nvpz,idimp,nbmax,mx1,myp1,mzp1,mxzyp1,irc)
! this subroutine moves particles into appropriate spatial regions in y
! and z, for distributed data, with 2d domain decomposition in y/z.
! tiles are assumed to be arranged in 3D linear memory
! output: rbufr, rbufl, mcll, mclr
! sbufl = buffer for particles being sent to lower/back processor
! sbufr = buffer for particles being sent to upper/forward processor
! rbufl = buffer for particles being received from lower/back processor
! rbufr = buffer for particles being received from upper/forward
! processor
! ncll = particle number offsets sent to lower/back processor
! nclr = particle number offsets sent to upper/forward processor
! mcll = particle number offsets received from lower/back processor
! mclr = particle number offsets received from upper/forward processor
! mcls = particle number ofsets received from corner processors
! kstrt = starting data block number
! nvpy/nvpz = number of real or virtual processors in y/z
! idimp = size of phase space = 4 or 5
! nbmax =  size of buffers for passing particles between processors
! mx1 = (system length in x direction - 1)/mx + 1
! myp1 = (partition length in y direction - 1)/my + 1
! mzp1 = (partition length in z direction - 1)/mz + 1
! mxzyp1 = mx1*max(myp1,mzp1)
! irc = maximum overflow, returned only if error occurs, when irc > 0
      implicit none
      integer, intent(in) :: kstrt, nvpy, nvpz, idimp, nbmax
      integer, intent(in) :: mx1, myp1, mzp1, mxzyp1
      integer, intent(inout) :: irc
      real, dimension(idimp,nbmax,2), intent(in) :: sbufr, sbufl
      real, dimension(idimp,nbmax,2), intent(inout) :: rbufr, rbufl
      integer, dimension(3,mxzyp1,3,2), intent(inout) :: ncll, nclr
      integer, dimension(3,mxzyp1,3,2), intent(inout) :: mcll, mclr
      integer, dimension(3,mx1+1,4), intent(inout) :: mcls
! lgrp = current communicator
! mint = default datatype for integers
! mreal = default datatype for reals
! local data
      integer :: ierr, js, ks, kl, kr, i, j, k, n, jsl, jsr
      integer :: m, ll, lr, krr, krl, klr, kll, jsrr, jsrl, jslr, jsll
      integer :: nr, nl, mr, ml, nbr, nbl
      integer :: mxyp1, mxzp1, nbsize, ncsize, nsize
      integer, dimension(8) :: msid
      integer, dimension(12) :: itg
      integer, dimension(lstat) :: istatus
      integer, dimension(1) :: nb, iwork
      data itg /3,4,5,6,7,8,9,10,11,12,13,14/
! js/ks = processor co-ordinates in y/z => idproc = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      mxyp1 = mx1*myp1
      mxzp1 = mx1*mzp1
      nbsize = idimp*nbmax
      ncsize = 9*mxzyp1
! copy particle buffers in y:
! update rbufl(:,1), rbufr(:,1), mcll(:,1), mclr(:,1)
! special case for one processor
      if ((nvpy*nvpz)==1) then
!$OMP PARALLEL
!$OMP DO PRIVATE(i,j,k,ll)
         do ll = 1, 3*mxzp1
            k = (ll - 1)/mxzp1
            j = ll - mxzp1*k
            k = k + 1
            do i = 1, 3
               mcll(i,j,k,1) = nclr(i,j,k,1)
               mclr(i,j,k,1) = ncll(i,j,k,1)
            enddo
         enddo
!$OMP END DO NOWAIT
!$OMP DO PRIVATE(i,j)
         do j = 1, nclr(3,mxzp1,3,1)
            do i = 1, idimp
               rbufl(i,j,1) = sbufr(i,j,1)
            enddo
         enddo
!$OMP END DO NOWAIT
!$OMP DO PRIVATE(i,j)
         do j = 1, ncll(3,mxzp1,3,1)
            do i = 1, idimp
               rbufr(i,j,1) = sbufl(i,j,1)
            enddo
         enddo
!$OMP END DO
!$OMP END PARALLEL
! get particles from corners
         n = mx1*(mzp1 - 1)
! zero out base addresses in prefix scans
         if (n > 0) then
            nr = nclr(3,n,3,1)
            nl = ncll(3,n,3,1)
         else
            nr = nclr(3,mxzp1,2,1)
            nl = ncll(3,mxzp1,2,1)
         endif
         do j = 1, mx1
            do i = 1, 3
               nclr(i,j,2,1) = nclr(i,j,2,1) - nclr(3,mxzp1,1,1)
               nclr(i,n+j,3,1) = nclr(i,n+j,3,1) - nr
               ncll(i,j,2,1) = ncll(i,j,2,1) - ncll(3,mxzp1,1,1)
               ncll(i,n+j,3,1) = ncll(i,n+j,3,1) - nl
            enddo
         enddo
! add new base addresses in prefix scans
         ml = mcll(3,mxzp1,3,1)
         mr = mclr(3,mxzp1,3,1)
         do j = 1, mx1
            do i = 1, 3
               mcls(i,j,1) = nclr(i,j,2,1) + ml
               mcls(i,j,3) = ncll(i,j,2,1) + mr
            enddo
         enddo
         mcls(1,mx1+1,1) = ml
         mcls(1,mx1+1,3) = mr
! append corner particles to end of buffers
         k = nclr(3,mx1,2,1)
         m = nclr(3,mxzp1,1,1)
         do j = 1, k
            do i = 1, idimp
               rbufl(i,j+ml,1) = sbufr(i,j+m,1)
            enddo
         enddo
         ml = ml + k
         k = ncll(3,mx1,2,1)
         m = ncll(3,mxzp1,1,1)
         do j = 1, k
            do i = 1, idimp
               rbufr(i,j+mr,1) = sbufl(i,j+m,1)
            enddo
         enddo
         mr = mr + k
! add new base addresses in prefix scans
         do j = 1, mx1
            do i = 1, 3
               mcls(i,j,2) = nclr(i,n+j,3,1) + ml
               mcls(i,j,4) = ncll(i,n+j,3,1) + mr
            enddo
         enddo
         mcls(1,mx1+1,2) = ml
         mcls(1,mx1+1,4) = mr
! append more corner particles to end of buffers
         do j = 1, nclr(3,n+mx1,3,1)
            do i = 1, idimp
               rbufl(i,j+ml,1) = sbufr(i,j+nr,1)
            enddo
         enddo
         do j = 1, ncll(3,n+mx1,3,1)
            do i = 1, idimp
               rbufr(i,j+mr,1) = sbufl(i,j+nl,1)
            enddo
         enddo
! this segment is used for mpi computers
      else
! get particles from below and above
         kr = js + 1
         if (kr >= nvpy) kr = kr - nvpy
         kl = js - 1
         if (kl < 0) kl = kl + nvpy
         kr = kr + nvpy*ks
         kl = kl + nvpy*ks
! post receives
         call MPI_IRECV(mcll(1,1,1,1),ncsize,mint,kl,itg(1),lgrp,msid(1)&
     &,ierr)
         call MPI_IRECV(mclr(1,1,1,1),ncsize,mint,kr,itg(2),lgrp,msid(2)&
     &,ierr)
         call MPI_IRECV(rbufl(1,1,1),nbsize,mreal,kl,itg(3),lgrp,msid(3)&
     &,ierr)
         call MPI_IRECV(rbufr(1,1,1),nbsize,mreal,kr,itg(4),lgrp,msid(4)&
     &,ierr)
! send particle number offsets
         call MPI_ISEND(nclr(1,1,1,1),ncsize,mint,kr,itg(1),lgrp,msid(5)&
     &,ierr)
         call MPI_ISEND(ncll(1,1,1,1),ncsize,mint,kl,itg(2),lgrp,msid(6)&
     &,ierr)
         call MPI_WAIT(msid(1),istatus,ierr)
         call MPI_WAIT(msid(2),istatus,ierr)
! send particles
         jsr = idimp*nclr(3,mxzp1,3,1)
         call MPI_ISEND(sbufr(1,1,1),jsr,mreal,kr,itg(3),lgrp,msid(7),  &
     &ierr)
         jsl = idimp*ncll(3,mxzp1,3,1)
         call MPI_ISEND(sbufl(1,1,1),jsl,mreal,kl,itg(4),lgrp,msid(8),  &
     &ierr)
         call MPI_WAIT(msid(3),istatus,ierr)
         call MPI_WAIT(msid(4),istatus,ierr)
! make sure sbufr, sbufl, ncll, and nclr have been sent
         do i = 1, 4
            call MPI_WAIT(msid(i+4),istatus,ierr)
         enddo
! get particles from corners
         kr = js + 1
         if (kr >= nvpy) kr = kr - nvpy
         kl = js - 1
         if (kl < 0) kl = kl + nvpy
         lr = ks + 1
         if (lr >= nvpz) lr = lr - nvpz
         ll = ks - 1
         if (ll < 0) ll = ll + nvpz
         krl = kr + nvpy*ll
         krr = kr + nvpy*lr
         kll = kl + nvpy*ll
         klr = kl + nvpy*lr
         nsize = 3*mx1
         n = mx1*(mzp1 - 1)
! zero out base addresses in prefix scans
         if (n > 0) then
            nr = nclr(3,n,3,1)
            nl = ncll(3,n,3,1)
         else
            nr = nclr(3,mxzp1,2,1)
            nl = ncll(3,mxzp1,2,1)
         endif
         do j = 1, mx1
            do i = 1, 3
               nclr(i,j,2,1) = nclr(i,j,2,1) - nclr(3,mxzp1,1,1)
               nclr(i,n+j,3,1) = nclr(i,n+j,3,1) - nr
               ncll(i,j,2,1) = ncll(i,j,2,1) - ncll(3,mxzp1,1,1)
               ncll(i,n+j,3,1) = ncll(i,n+j,3,1) - nl
            enddo
         enddo
         n = n + 1
! post receives
         call MPI_IRECV(mcls(1,1,1),nsize,mint,klr,itg(5),lgrp,msid(1), &
     &ierr)
         call MPI_IRECV(mcls(1,1,2),nsize,mint,kll,itg(6),lgrp,msid(2), &
     &ierr)
         call MPI_IRECV(mcls(1,1,3),nsize,mint,krr,itg(7),lgrp,msid(3), &
     &ierr)
         call MPI_IRECV(mcls(1,1,4),nsize,mint,krl,itg(8),lgrp,msid(4), &
     &ierr)
! send particle number offsets
         call MPI_ISEND(nclr(1,1,2,1),nsize,mint,krl,itg(5),lgrp,msid(5)&
     &,ierr)
         call MPI_ISEND(nclr(1,n,3,1),nsize,mint,krr,itg(6),lgrp,msid(6)&
     &,ierr)
         call MPI_ISEND(ncll(1,1,2,1),nsize,mint,kll,itg(7),lgrp,msid(7)&
     &,ierr)
         call MPI_ISEND(ncll(1,n,3,1),nsize,mint,klr,itg(8),lgrp,msid(8)&
     &,ierr)
! make sure particle offsets have been sent to and received from corners
         do i = 1, 8
            call MPI_WAIT(msid(i),istatus,ierr)
         enddo
! check for overflow errors
         ml = mcll(3,mxzp1,3,1)
         mr = mclr(3,mxzp1,3,1)
         nbl = nbmax - (ml + (mcls(3,mx1,1) + mcls(3,mx1,2)))
         nbr = nbmax - (mr + (mcls(2,mx1,3) + mcls(3,mx1,4)))
         nb(1) = min(-nbl,-nbr)
         call PPIMAX(nb,iwork,1)
         if (nb(1) > 0) then
            write (*,*) kstrt, 'corner buffer overflow error = ', nb(1)
            irc = nb(1)
            return
         endif
         nbl = idimp*nbl
         nbr = idimp*nbr
! add new base addresses in prefix scans
         do j = 1, mx1
            do i = 1, 3
               mcls(i,j,1) = mcls(i,j,1) + ml
               mcls(i,j,3) = mcls(i,j,3) + mr
            enddo
         enddo
         mcls(1,mx1+1,1) = ml
         mcls(1,mx1+1,3) = mr
! post first part of particle receives, append to end
         ml = ml + 1
         call MPI_IRECV(rbufl(1,ml,1),nbl,mreal,klr,itg(9),lgrp,msid(1),&
     &ierr)
         mr = mr + 1
         call MPI_IRECV(rbufr(1,mr,1),nbr,mreal,krr,itg(11),lgrp,msid(3)&
     &,ierr)
! send first part of particles
         m = nclr(3,mxzp1,1,1) + 1
         jsrl = idimp*nclr(3,mx1,2,1)
         call MPI_ISEND(sbufr(1,m,1),jsrl,mreal,krl,itg(9),lgrp,msid(5),&
     &ierr)
         m = ncll(3,mxzp1,1,1) + 1
         jsll = idimp*ncll(3,mx1,2,1)
         call MPI_ISEND(sbufl(1,m,1),jsll,mreal,kll,itg(11),lgrp,msid(7)&
     &,ierr)
         call MPI_WAIT(msid(1),istatus,ierr)
         call MPI_GET_COUNT(istatus,mreal,m,ierr)
         nbl = nbl - m
         m = m/idimp
         ml = ml + m - 1
         call MPI_WAIT(msid(3),istatus,ierr)
         call MPI_GET_COUNT(istatus,mreal,m,ierr)
         nbr = nbr - idimp*m
         m = m/idimp
         mr = mr + m - 1
! add new base addresses in prefix scans
         do j = 1, mx1
            do i = 1, 3
               mcls(i,j,2) = mcls(i,j,2) + ml
               mcls(i,j,4) = mcls(i,j,4) + mr
            enddo
         enddo
         mcls(1,mx1+1,2) = ml
         mcls(1,mx1+1,4) = mr
! post second part of particle receives, append to end
         ml = ml + 1
         call MPI_IRECV(rbufl(1,ml,1),nbl,mreal,kll,itg(10),lgrp,msid(2)&
     &,ierr)
         mr = mr + 1
         call MPI_IRECV(rbufr(1,mr,1),nbr,mreal,krl,itg(12),lgrp,msid(4)&
     &,ierr)
! send second part of particles
         jsrr = idimp*nclr(3,n+mx1-1,3,1)
         m = nr + 1
         call MPI_ISEND(sbufr(1,m,1),jsrr,mreal,krr,itg(10),lgrp,msid(6)&
     &,ierr)
         jslr = idimp*ncll(3,n+mx1-1,3,1)
         m = nl + 1
         call MPI_ISEND(sbufl(1,m,1),jslr,mreal,klr,itg(12),lgrp,msid(8)&
     &,ierr)
         call MPI_WAIT(msid(2),istatus,ierr)
         call MPI_WAIT(msid(4),istatus,ierr)
! make sure sbufr and sbufl have been sent to corners
         do i = 1, 4
            call MPI_WAIT(msid(i+4),istatus,ierr)
         enddo
      endif
! copy particle buffers in z:
! update rbufl(:,2), rbufr(:,2), mcll(:,2), mclr(:,2)
! special case for one processor
      if ((nvpy*nvpz)==1) then
!$OMP PARALLEL
!$OMP DO PRIVATE(i,j,k,ll)
         do ll = 1, 3*mxyp1
            k = (ll - 1)/mxyp1
            j = ll - mxyp1*k
            k = k + 1
            do i = 1, 3
               mcll(i,j,k,2) = nclr(i,j,k,2)
               mclr(i,j,k,2) = ncll(i,j,k,2)
            enddo
         enddo
!$OMP END DO NOWAIT
!$OMP DO PRIVATE(i,j)
         do j = 1, nclr(3,mxyp1,3,2)
            do i = 1, idimp
               rbufl(i,j,2) = sbufr(i,j,2)
            enddo
         enddo
!$OMP END DO NOWAIT
!$OMP DO PRIVATE(i,j)
         do j = 1, ncll(3,mxyp1,3,2)
            do i = 1, idimp
               rbufr(i,j,2) = sbufl(i,j,2)
            enddo
         enddo
!$OMP END DO
!$OMP END PARALLEL
! this segment is used for mpi computers
      else
! get particles from back and front
         kr = ks + 1
         if (kr >= nvpz) kr = kr - nvpz
         kl = ks - 1
         if (kl < 0) kl = kl + nvpz
         kr = js + nvpy*kr
         kl = js + nvpy*kl
! post receives
         call MPI_IRECV(mcll(1,1,1,2),ncsize,mint,kl,itg(1),lgrp,msid(1)&
     &,ierr)
         call MPI_IRECV(mclr(1,1,1,2),ncsize,mint,kr,itg(2),lgrp,msid(2)&
     &,ierr)
         call MPI_IRECV(rbufl(1,1,2),nbsize,mreal,kl,itg(3),lgrp,msid(3)&
     &,ierr)
         call MPI_IRECV(rbufr(1,1,2),nbsize,mreal,kr,itg(4),lgrp,msid(4)&
     &,ierr)
! send particle number offsets
         call MPI_ISEND(nclr(1,1,1,2),ncsize,mint,kr,itg(1),lgrp,msid(5)&
     &,ierr)
         call MPI_ISEND(ncll(1,1,1,2),ncsize,mint,kl,itg(2),lgrp,msid(6)&
     &,ierr)
         call MPI_WAIT(msid(1),istatus,ierr)
         call MPI_WAIT(msid(2),istatus,ierr)
! send particles
         jsr = idimp*nclr(3,mxyp1,3,2)
         call MPI_ISEND(sbufr(1,1,2),jsr,mreal,kr,itg(3),lgrp,msid(7),  &
     &ierr)
         jsl = idimp*ncll(3,mxyp1,3,2)
         call MPI_ISEND(sbufl(1,1,2),jsl,mreal,kl,itg(4),lgrp,msid(8),  &
     &ierr)
         call MPI_WAIT(msid(3),istatus,ierr)
         call MPI_WAIT(msid(4),istatus,ierr)
! make sure sbufr, sbufl, ncll, and nclr have been sent
         do i = 1, 4
            call MPI_WAIT(msid(i+4),istatus,ierr)
         enddo
      endif
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPWRITE32(f,g,nx,ny,nz,kyp,kzp,nvpy,nxv,nypmx,nzpmx,   &
     &iunit,nrec)
! this subroutine collects distributed real 3d scalar data f and writes
! to a direct access binary file with 2D spatial decomposition
! data must have a uniform partition
! f = input data to be written
! g = scratch data
! nx/ny/nz = system length in x/y/z direction
! kyp/kzp = number of data values per block in y/z
! nvpy = number of real or virtual processors in y
! nxv = first dimension of data array f, must be >= nx
! nypmx = second dimension of data array f, must be >= kyp
! nzpmx = third dimension of data array f, must be >= kzp
! iunit = fortran unit number
! nrec = current record number for write, if nrec > 0
! input: all, output: nrec
      implicit none
      integer, intent(in) :: nx, ny, nz, kyp, kzp, nvpy, nxv
      integer, intent(in) :: nypmx, nzpmx, iunit
      integer, intent(inout) :: nrec
      real, intent(in), dimension(nxv,nypmx,nzpmx) :: f
      real, intent(inout), dimension(nxv,nypmx,nzpmx) :: g
! lgrp = current communicator
! mint = default datatype for integers
! mreal = default datatype for reals
! local data
      integer :: nvp, idproc, igo, js, ks, nxyv, nzp, kypp, kzpp
      integer :: id, i, j, k, l, ierr
      integer :: nsid, msid
      integer, dimension(lstat) :: istatus
      nxyv = nxv*nypmx
      nzp = nxyv*kzp
      igo = 1
! this segment is used for shared memory computers
!     write (unit=iunit,rec=nrec) (((f(j,k,l),j=1,nx),k=1,kyp),l=1,kzp)
!     nrec = nrec + 1
! this segment is used for mpi computers
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! determine the size of the group associated with a communicator
      call MPI_COMM_SIZE(lgrp,nvp,ierr)
! js/ks = processor co-ordinates in y/z => idproc = js + nvpy*ks
      ks = idproc/nvpy
      js = idproc - nvpy*ks
! kypp = actual size to send in y direction
      kypp = min(kyp,max(0,ny-kyp*js))
! kzpp = actual size to send in z direction
      kzpp = min(kzp,max(0,nz-kzp*ks))
! node 0 receives messages from other nodes
      if (idproc==0) then
! first write data for node 0
         write (unit=iunit,rec=nrec) (((f(j,k,l),j=1,nx),k=1,kyp),l=1,  &
     &kzp)
         nrec = nrec + 1
! then write data from remaining nodes
         do i = 2, nvp
         id = i - 1
! send go signal to sending node
         call MPI_SEND(igo,1,mint,id,98,lgrp,ierr)
         call MPI_IRECV(kypp,1,mint,id,100,lgrp,nsid,ierr)
         call MPI_IRECV(g,nzp,mreal,id,99,lgrp,msid,ierr)
         call MPI_WAIT(nsid,istatus,ierr)
         call MPI_WAIT(msid,istatus,ierr)
         call MPI_GET_COUNT(istatus,mreal,kzpp,ierr)
         kzpp = kzpp/nxyv
         if (kypp*kzpp > 0) then
            write (unit=iunit,rec=nrec) (((g(j,k,l),j=1,nx),k=1,kyp),   &
     &l=1,kzp)
            nrec = nrec + 1
         endif
         enddo
! other nodes send data to node 0 after receiving go signal
      else
         call MPI_IRECV(igo,1,mint,0,98,lgrp,msid,ierr)
         call MPI_WAIT(msid,istatus,ierr)
         call MPI_SEND(kypp,1,mint,0,100,lgrp,ierr)
         if ((kypp*kzpp)==0) nzp = 0
         call MPI_SEND(f,nzp,mreal,0,99,lgrp,ierr)
      endif
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPREAD32(f,g,nx,ny,nz,kyp,kzp,nvpy,nxv,nypmx,nzpmx,    &
     &iunit,nrec,irc)
! this subroutine reads real 3d scalar data f from a direct access
! binary file and distributes it with 2D spatial decomposition
! data must have a uniform partition
! f = output data to be read
! g = scratch data
! nx/ny/nz = system length in x/y/z direction
! kyp/kzp = number of data values per block in y/z
! nvpy = number of real or virtual processors in y
! nxv = first dimension of data array f, must be >= nx
! nypmx = second dimension of data array f, must be >= kyp
! nzpmx = third dimension of data array f, must be >= kzp
! iunit = fortran unit number
! nrec = current record number for read, if nrec > 0
! irc = error indicator
! input: all, output: f, nrec, irc
      implicit none
      integer, intent(in) :: nx, ny, nz, kyp, kzp, nvpy, nxv
      integer, intent(in) :: nypmx, nzpmx, iunit
      integer, intent(inout) :: nrec, irc
      real, intent(inout), dimension(nxv,nypmx,nzpmx) :: f, g
! lgrp = current communicator
! mreal = default datatype for reals
! local data
      integer :: nvp, idproc, js, ks, nxyv, nzp, nzps, kypp, kzpp
      integer :: id, i, j, k, l, ios, ierr
      integer, dimension(1) :: nrc, iwrk1
      integer, dimension(lstat) :: istatus
      nxyv = nxv*nypmx
      nzp = nxyv*kzp
      nrc(1) = 0
! this segment is used for shared memory computers
!     read (unit=iunit,rec=nrec,iostat=ios) (((f(j,k,l),j=1,nx),k=1,kyp)&
!    &,l=1,kzp)
!     if (ios /= 0) nrc(1) = 1
!     nrec = nrec + 1
! this segment is used for mpi computers
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! determine the size of the group associated with a communicator
      call MPI_COMM_SIZE(lgrp,nvp,ierr)
! node 0 receives messages from other nodes
      if (idproc.eq.0) then
! first read data for node 0
         read (unit=iunit,rec=nrec,iostat=ios) (((f(j,k,l),j=1,nx),     &
     &k=1,kyp),l=1,kzp)
         if (ios /= 0) nrc(1) = 1
         nrec = nrec + 1
! then read data on node 0 to send to remaining nodes
         do i = 2, nvp
            id = i - 1
! js/ks = processor co-ordinates in y/z => idproc = js + nvpy*ks
            ks = id/nvpy
            js = id - nvpy*ks
            kypp = min(kyp,max(0,ny-kyp*js))
            kzpp = min(kzp,max(0,nz-kzp*ks))
            if (kypp*kzpp > 0) then
               read (unit=iunit,rec=nrec,iostat=ios) (((g(j,k,l),j=1,nx)&
     &,k=1,kyp),l=1,kzp)
               if (ios /= 0) then
                  if (nrc(1) /= 0) nrc(1) = i
               endif
               nrec = nrec + 1
            endif
! send data from node 0
            nzps = nzp
            if ((kypp*kzpp)==0) nzps = 0
            call MPI_SEND(g,nzps,mreal,id,98,lgrp,ierr)
         enddo
! other nodes receive data from node 0
      else 
         call MPI_RECV(f,nzp,mreal,0,98,lgrp,istatus,ierr)
      endif
! check for error condition
      call PPIMAX(nrc,iwrk1,1)
      irc = nrc(1)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPVWRITE32(f,g,nx,ny,nz,kyp,kzp,nvpy,ndim,nxv,nypmx,   &
     &nzpmx,iunit,nrec)
! this subroutine collects distributed real 3d vector data f and writes
! to a direct access binary file with 2D spatial decomposition
! data must have a uniform partition
! f = input data to be written
! g = scratch data
! nx/ny/nz = system length in x/y/z direction
! kyp/kzp = number of data values per block in y/z
! nvpy = number of real or virtual processors in y
! ndim = first dimension of data array f
! nxv = second dimension of data array f, must be >= nx
! nypmx = third dimension of data array f, must be >= kyp
! nzpmx = fourth dimension of data array f, must be >= kzp
! iunit = fortran unit number
! nrec = current record number for write, if nrec > 0
! input: all, output: nrec
      implicit none
      integer, intent(in) :: nx, ny, nz, kyp, kzp, nvpy, ndim, nxv
      integer, intent(in) :: nypmx, nzpmx, iunit
      integer, intent(inout) :: nrec
      real, intent(in), dimension(ndim,nxv,nypmx,nzpmx) :: f
      real, intent(inout), dimension(ndim,nxv,nypmx,nzpmx) :: g
! lgrp = current communicator
! mint = default datatype for integers
! mreal = default datatype for reals
! local data
      integer :: nvp, idproc, igo, js, ks, nnxyv, nnzp, kypp, kzpp
      integer :: id, i, j, k, l, n, ierr
      integer :: nsid, msid
      integer, dimension(lstat) :: istatus
      nnxyv = ndim*nxv*nypmx
      nnzp = nnxyv*kzp
      igo = 1
! this segment is used for shared memory computers
!     write (unit=iunit,rec=nrec) ((((f(n,j,k,l),n=1,ndim),j=1,nx),     &
!    &k=1,kyp),l=1,kzp)
!     nrec = nrec + 1
! this segment is used for mpi computers
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! determine the size of the group associated with a communicator
      call MPI_COMM_SIZE(lgrp,nvp,ierr)
! js/ks = processor co-ordinates in y/z => idproc = js + nvpy*ks
      ks = idproc/nvpy
      js = idproc - nvpy*ks
! kypp = actual size to send in y direction
      kypp = min(kyp,max(0,ny-kyp*js))
! kzpp = actual size to send in z direction
      kzpp = min(kzp,max(0,nz-kzp*ks))
! node 0 receives messages from other nodes
      if (idproc==0) then
! first write data for node 0
         write (unit=iunit,rec=nrec) ((((f(n,j,k,l),n=1,ndim),j=1,nx),  &
     &k=1,kyp),l=1,kzp)
         nrec = nrec + 1
! then write data from remaining nodes
         do i = 2, nvp
         id = i - 1
! send go signal to sending node
         call MPI_SEND(igo,1,mint,id,98,lgrp,ierr)
         call MPI_IRECV(kypp,1,mint,id,100,lgrp,nsid,ierr)
         call MPI_IRECV(g,nnzp,mreal,id,99,lgrp,msid,ierr)
         call MPI_WAIT(nsid,istatus,ierr)
         call MPI_WAIT(msid,istatus,ierr)
         call MPI_GET_COUNT(istatus,mreal,kzpp,ierr)
         kzpp = kzpp/nnxyv
         if (kypp*kzpp > 0) then
            write (unit=iunit,rec=nrec) ((((g(n,j,k,l),n=1,ndim),j=1,nx)&
     &,k=1,kyp),l=1,kzp)
            nrec = nrec + 1
         endif
         enddo
! other nodes send data to node 0 after receiving go signal
      else
         call MPI_IRECV(igo,1,mint,0,98,lgrp,msid,ierr)
         call MPI_WAIT(msid,istatus,ierr)
         call MPI_SEND(kypp,1,mint,0,100,lgrp,ierr)
         if ((kypp*kzpp)==0) nnzp = 0
         call MPI_SEND(f,nnzp,mreal,0,99,lgrp,ierr)
      endif
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPVREAD32(f,g,nx,ny,nz,kyp,kzp,nvpy,ndim,nxv,nypmx,    &
     &nzpmx,iunit,nrec,irc)
! this subroutine reads real 3d vector data f from a direct access
! binary file and distributes it with 2D spatial decomposition
! data must have a uniform partition
! f = output data to be read
! g = scratch data
! nx/ny/nz = system length in x/y/z direction
! kyp/kzp = number of data values per block in y/z
! nvpy = number of real or virtual processors in y
! ndim = first dimension of data array f
! nxv = second dimension of data array f, must be >= nx
! nypmx = third dimension of data array f, must be >= kyp
! nzpmx = fourth dimension of data array f, must be >= kzp
! iunit = fortran unit number
! nrec = current record number for read, if nrec > 0
! irc = error indicator
! input: all, output: f, nrec, irc
      implicit none
      integer, intent(in) :: nx, ny, nz, kyp, kzp, nvpy, ndim, nxv
      integer, intent(in) :: nypmx, nzpmx, iunit
      integer, intent(inout) :: nrec, irc
      real, intent(inout), dimension(ndim,nxv,nypmx,nzpmx) :: f, g
! lgrp = current communicator
! mreal = default datatype for reals
! local data
      integer :: nvp, idproc, js, ks, nnxyv, nnzp, nnzps, kypp, kzpp
      integer :: id, i, j, k, l, n, ios, ierr
      integer, dimension(1) :: nrc, iwrk1
      integer, dimension(lstat) :: istatus
      nnxyv = ndim*nxv*nypmx
      nnzp = nnxyv*kzp
      nrc(1) = 0
! this segment is used for shared memory computers
!     read (unit=iunit,rec=nrec,iostat=ios) ((((f(n,j,k,l),n=1,ndim),   &
!    &j=1,nx),k=1,kyp),l=1,kzp)
!     if (ios /= 0) nrc(1) = 1
!     nrec = nrec + 1
! this segment is used for mpi computers
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! determine the size of the group associated with a communicator
      call MPI_COMM_SIZE(lgrp,nvp,ierr)
! node 0 receives messages from other nodes
      if (idproc.eq.0) then
! first read data for node 0
         read (unit=iunit,rec=nrec,iostat=ios) ((((f(n,j,k,l),n=1,ndim),&
     &j=1,nx),k=1,kyp),l=1,kzp)
         if (ios /= 0) nrc(1) = 1
         nrec = nrec + 1
! then read data on node 0 to send to remaining nodes
         do i = 2, nvp
            id = i - 1
! js/ks = processor co-ordinates in y/z => idproc = js + nvpy*ks
            ks = id/nvpy
            js = id - nvpy*ks
            kypp = min(kyp,max(0,ny-kyp*js))
            kzpp = min(kzp,max(0,nz-kzp*ks))
            if (kypp*kzpp > 0) then
               read (unit=iunit,rec=nrec,iostat=ios) ((((g(n,j,k,l),    &
     &n=1,ndim),j=1,nx),k=1,kyp),l=1,kzp)
               if (ios /= 0) then
                  if (nrc(1) /= 0) nrc(1) = i
               endif
               nrec = nrec + 1
            endif
! send data from node 0
            nnzps = nnzp
            if ((kypp*kzpp)==0) nnzps = 0
            call MPI_SEND(g,nnzps,mreal,id,98,lgrp,ierr)
         enddo
! other nodes receive data from node 0
      else 
         call MPI_RECV(f,nnzp,mreal,0,98,lgrp,istatus,ierr)
      endif
! check for error condition
      call PPIMAX(nrc,iwrk1,1)
      irc = nrc(1)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPWRPART3(part,npp,idimp,npmax,iunit,iscr)
! this subroutine collects distributed particle data part and writes to
! a fortran unformatted file with spatial decomposition
! part = input data to be written
! npp = number of particles in partition
! idimp = size of phase space = 6
! npmax = maximum number of particles in each partition
! iunit = fortran unit number
! iscr = unused unit number available for scratch file
      implicit none
      integer, intent(in) :: npp, idimp, npmax, iunit, iscr
      real, intent(inout), dimension(idimp,npmax) :: part
! lgrp = current communicator
! mint = default datatype for integers
! mreal = default datatype for reals
! local data
      integer :: nvp, idproc, igo, ndp, id, i, j, k, ierr
      integer :: msid
      integer, dimension(lstat) :: istatus
      igo = 1
! this segment is used for shared memory computers
!     write (unit=iunit) ((part(j,k),j=1,idimp),k=1,npp)
! this segment is used for mpi computers
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! determine the size of the group associated with a communicator
      call MPI_COMM_SIZE(lgrp,nvp,ierr)
! node 0 receives messages from other nodes
      if (idproc==0) then
! first write particle data for node 0 to scratch array
         if (nvp > 1) then
            open(unit=iscr,form='unformatted',status='scratch')
            if (npp > 0) then
               write (iscr) ((part(j,k),j=1,idimp),k=1,npp)
            endif
         endif
! write particle data for node 0 to restart file
         write (unit=iunit) npp
         if (npp > 0) then
            write (unit=iunit)  ((part(j,k),j=1,idimp),k=1,npp)
         endif
! then write data from remaining nodes
         do i = 2, nvp
         id = i - 1
! send go signal to sending node
         call MPI_SEND(igo,1,mint,id,98,lgrp,ierr)
         call MPI_IRECV(part,idimp*npmax,mreal,id,99,lgrp,msid,ierr)
         call MPI_WAIT(msid,istatus,ierr)
         call MPI_GET_COUNT(istatus,mreal,ndp,ierr)
         ndp = ndp/idimp
         write (unit=iunit) ndp
         if (ndp > 0) then
            write (unit=iunit) ((part(j,k),j=1,idimp),k=1,ndp)
         endif
         enddo
! read back particle data for node 0 from scratch array
         if (nvp > 1) then
            rewind iscr
            if (npp > 0) then
               read (iscr) ((part(j,k),j=1,idimp),k=1,npp)
            endif
            close (iscr)
         endif
! other nodes send data to node 0 after receiving go signal
      else
         call MPI_IRECV(igo,1,mint,0,98,lgrp,msid,ierr)
         call MPI_WAIT(msid,istatus,ierr)
         ndp = idimp*npp
         call MPI_SEND(part,ndp,mreal,0,99,lgrp,ierr)
      endif
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPRDPART3(part,npp,idimp,npmax,iunit,iscr,irc)
! this subroutine reads particle data part from a fortran unformatted
! file and distributes it with spatial decomposition
! part = output data to be read
! npp = number of particles in partition
! idimp = size of phase space = 6
! npmax = maximum number of particles in each partition
! iunit = fortran unit number
! iscr = unused unit number available for scratch file
! irc = error indicator
! input: all except part, npp, irc, output: part, npp, irc
      implicit none
      integer, intent(in) :: idimp, npmax, iunit, iscr
      integer, intent(inout) :: npp, irc
      real, intent(inout), dimension(idimp,npmax) :: part
! lgrp = current communicator
! mreal = default datatype for reals
! local data
      integer :: nvp, idproc, ndp, id, i, j, k, ios, ierr
      integer, dimension(1) :: nrc, iwrk1
      integer, dimension(lstat) :: istatus
      nrc(1) = 0
! this segment is used for shared memory computers
!     read (unit=iunit,iostat=ios) (((part(j,k),j=1,idimp),k=1,npp)
!     if (ios /= 0) nrc(1) = 1
!     nrec = nrec + 1
! this segment is used for mpi computers
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! determine the size of the group associated with a communicator
      call MPI_COMM_SIZE(lgrp,nvp,ierr)
! node 0 receives messages from other nodes
      if (idproc==0) then
! first read data for node 0
         read (unit=iunit,iostat=ios) npp
         if (ios /= 0) nrc(1) = 1
         if (npp > 0) then
            read (unit=iunit,iostat=ios) ((part(j,k),j=1,idimp),k=1,npp)
         endif
         if (ios /= 0) nrc(1) = 1
! then write particle data for node 0 to scratch array
         if (nvp > 1) then
            open(unit=iscr,form='unformatted',status='scratch')
            if (npp > 0) then
               write (iscr) ((part(j,k),j=1,idimp),k=1,npp)
            endif
         endif
! then read data on node 0 to send to remaining nodes
         do i = 2, nvp
            id = i - 1
            read (unit=iunit,iostat=ios) ndp
            if (ios /= 0) nrc(1) = 1
            if (ndp > 0) then
               read (unit=iunit,iostat=ios) ((part(j,k),j=1,idimp),     &
     &k=1,ndp)
               if (ios /= 0) then
                  if (nrc(1) /= 0) nrc(1) = i
               endif
            endif
! send data from node 0
            ndp = idimp*ndp
            call MPI_SEND(part,ndp,mreal,id,98,lgrp,ierr)
         enddo
! read back particle data for node 0 from scratch array
         if (nvp > 1) then
            rewind iscr
            if (npp > 0) then
               read (iscr) ((part(j,k),j=1,idimp),k=1,npp)
            endif
            close (iscr)
         endif
! other nodes receive data from node 0
      else 
         call MPI_RECV(part,idimp*npmax,mreal,0,98,lgrp,istatus,ierr)
         call MPI_GET_COUNT(istatus,mreal,ndp,ierr)
         npp = ndp/idimp
      endif
! check for error condition
      call PPIMAX(nrc,iwrk1,1)
      irc = nrc(1)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPWRDATA3(f,g,nxv,nypmx,nzpmx,iunit)
! this subroutine collects distributed periodic real 3d scalar data f
! and writes to a fortran unformatted file with spatial decomposition
! f = input data to be written
! g = scratch data
! nxv = first dimension of data array f
! nypmx = second dimension of data array f
! nzpmx = third dimension of data array f
! iunit = fortran unit number
! input: all
      implicit none
      integer, intent(in) :: nxv, nypmx, nzpmx, iunit
      real, intent(in), dimension(nxv,nypmx,nzpmx) :: f
      real, intent(inout), dimension(nxv,nypmx,nzpmx) :: g
! lgrp = current communicator
! mint = default datatype for integers
! mreal = default datatype for reals
! local data
      integer :: nvp, idproc, igo, nyzp, id, i, j, k, l, ierr
      integer :: msid
      integer, dimension(lstat) :: istatus
      nyzp = nxv*nypmx*nzpmx
      igo = 1
! this segment is used for shared memory computers
!     write (unit=iunit) (((f(j,k,l),j=1,nxv),k=1,nypmx),l=1,nzpmx)
! this segment is used for mpi computers
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! determine the size of the group associated with a communicator
      call MPI_COMM_SIZE(lgrp,nvp,ierr)
! node 0 receives messages from other nodes
      if (idproc==0) then
! first write data for node 0
         write (unit=iunit) (((f(j,k,l),j=1,nxv),k=1,nypmx),l=1,nzpmx)
! then write data from remaining nodes
         do i = 2, nvp
         id = i - 1
! send go signal to sending node
         call MPI_SEND(igo,1,mint,id,98,lgrp,ierr)
         call MPI_IRECV(g,nyzp,mreal,id,99,lgrp,msid,ierr)
         call MPI_WAIT(msid,istatus,ierr)
         write (unit=iunit) (((g(j,k,l),j=1,nxv),k=1,nypmx),l=1,nzpmx)
         enddo
! other nodes send data to node 0 after receiving go signal
      else
         call MPI_IRECV(igo,1,mint,0,98,lgrp,msid,ierr)
         call MPI_WAIT(msid,istatus,ierr)
         call MPI_SEND(f,nyzp,mreal,0,99,lgrp,ierr)
      endif
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPRDDATA3(f,g,nxv,nypmx,nzpmx,iunit,irc)
! this subroutine reads periodic real 3d scalar data f from a fortran
! unformatted file and distributes it with spatial decomposition
! f = output data to be read
! g = scratch data
! nxv = first dimension of data array f
! nypmx = second dimension of data array f
! nzpmx = third dimension of data array f
! iunit = fortran unit number
! irc = error indicator
! input: all, output: f, irc
      implicit none
      integer, intent(in) :: nxv, nypmx, nzpmx, iunit
      integer, intent(inout) :: irc
      real, intent(inout), dimension(nxv,nypmx,nzpmx) :: f, g
! lgrp = current communicator
! mreal = default datatype for reals
! local data
      integer :: nvp, idproc, nyzp, id, i, j, k, l, ios, ierr
      integer, dimension(1) :: nrc, iwrk1
      integer, dimension(lstat) :: istatus
      nyzp = nxv*nypmx*nzpmx
      nrc(1) = 0
! this segment is used for shared memory computers
!     read (unit=iunit,iostat=ios) (((f(j,k,l),j=1,nxv),k=1,nypmx),     &
!    &l=1,nzpmx)
!     if (ios /= 0) nrc(1) = 1
! this segment is used for mpi computers
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! determine the size of the group associated with a communicator
      call MPI_COMM_SIZE(lgrp,nvp,ierr)
! node 0 receives messages from other nodes
      if (idproc==0) then
! first read data for node 0
         read (unit=iunit,iostat=ios) (((f(j,k,l),j=1,nxv),k=1,nypmx),  &
     &l=1,nzpmx)
         if (ios /= 0) nrc(1) = 1
! then read data on node 0 to send to remaining nodes
         do i = 2, nvp
            id = i - 1
            read (unit=iunit,iostat=ios) (((g(j,k,l),j=1,nxv),k=1,nypmx)&
     &,l=1,nzpmx)
            if (ios /= 0) then
               if (nrc(1) /= 0) nrc(1) = i
            endif
! send data from node 0
            call MPI_SEND(g,nyzp,mreal,id,98,lgrp,ierr)
         enddo
! other nodes receive data from node 0
      else 
         call MPI_RECV(f,nyzp,mreal,0,98,lgrp,istatus,ierr)
      endif
! check for error condition
      call PPIMAX(nrc,iwrk1,1)
      irc = nrc(1)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPWRVDATA3(f,g,ndim,nxv,nypmx,nzpmx,iunit)
! this subroutine collects distributed periodic real 3d vector data f
! and writes to a fortran unformatted file with spatial decomposition
! f = input data to be written
! g = scratch data
! ndim = first dimension of data array f
! nxv = second dimension of data array f
! nypmx = third dimension of data array f
! nzpmx = fourth dimension of data array f
! iunit = fortran unit number
! input: all
      implicit none
      integer, intent(in) :: ndim, nxv, nypmx, nzpmx, iunit
      real, intent(in), dimension(ndim,nxv,nypmx,nzpmx) :: f
      real, intent(inout), dimension(ndim,nxv,nypmx,nzpmx) :: g
! lgrp = current communicator
! mint = default datatype for integers
! mreal = default datatype for reals
! local data
      integer :: nvp, idproc, igo, nnyzp, id, i, j, k, l, n, ierr
      integer :: msid
      integer, dimension(lstat) :: istatus
      nnyzp = ndim*nxv*nypmx*nzpmx
      igo = 1
! this segment is used for shared memory computers
!     write (unit=iunit) ((((f(n,j,k,l),n=1,ndim),j=1,nxv),k=1,nypmx),  &
!    &l=1,nzpmx)
! this segment is used for mpi computers
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! determine the size of the group associated with a communicator
      call MPI_COMM_SIZE(lgrp,nvp,ierr)
! node 0 receives messages from other nodes
      if (idproc==0) then
! first write data for node 0
         write (unit=iunit) ((((f(n,j,k,l),n=1,ndim),j=1,nxv),k=1,nypmx)&
     &,l=1,nzpmx)
! then write data from remaining nodes
         do i = 2, nvp
         id = i - 1
! send go signal to sending node
         call MPI_SEND(igo,1,mint,id,98,lgrp,ierr)
         call MPI_IRECV(g,nnyzp,mreal,id,99,lgrp,msid,ierr)
         call MPI_WAIT(msid,istatus,ierr)
         write (unit=iunit) ((((g(n,j,k,l),n=1,ndim),j=1,nxv),k=1,nypmx)&
     &,l=1,nzpmx)
         enddo
! other nodes send data to node 0 after receiving go signal
      else
         call MPI_IRECV(igo,1,mint,0,98,lgrp,msid,ierr)
         call MPI_WAIT(msid,istatus,ierr)
         call MPI_SEND(f,nnyzp,mreal,0,99,lgrp,ierr)
      endif
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPRDVDATA3(f,g,ndim,nxv,nypmx,nzpmx,iunit,irc)
! this subroutine reads periodic real 3d vector data f from a fortran
! unformatted file and distributes it with spatial decomposition
! f = output data to be read
! g = scratch data
! ndim = first dimension of data array f
! nxv = second dimension of data array f
! nypmx = third dimension of data array f
! nzpmx = fourth dimension of data array f
! iunit = fortran unit number
! irc = error indicator
! input: all, output: f, irc
      implicit none
      integer, intent(in) :: ndim, nxv, nypmx, nzpmx, iunit
      integer, intent(inout) :: irc
      real, intent(inout), dimension(ndim,nxv,nypmx,nzpmx) :: f, g
! lgrp = current communicator
! mreal = default datatype for reals
! local data
      integer :: nvp, idproc, nnyzp, id, i, j, k, l, n, ios, ierr
      integer, dimension(1) :: nrc, iwrk1
      integer, dimension(lstat) :: istatus
      nnyzp = ndim*nxv*nypmx*nzpmx
      nrc(1) = 0
! this segment is used for shared memory computers
!     read (unit=iunit,iostat=ios) ((((f(n,j,k,l),n=1,ndim),j=1,nxv),     &
!    &k=1,nypmx),l=1,nzpmx)
!     if (ios /= 0) nrc(1) = 1
! this segment is used for mpi computers
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! determine the size of the group associated with a communicator
      call MPI_COMM_SIZE(lgrp,nvp,ierr)
! node 0 receives messages from other nodes
      if (idproc==0) then
! first read data for node 0
         read (unit=iunit,iostat=ios) ((((f(n,j,k,l),n=1,ndim),j=1,nxv),&
     &k=1,nypmx),l=1,nzpmx)
         if (ios /= 0) nrc(1) = 1
! then read data on node 0 to send to remaining nodes
         do i = 2, nvp
            id = i - 1
            read (unit=iunit,iostat=ios) ((((g(n,j,k,l),n=1,ndim),      &
     &j=1,nxv),k=1,nypmx),l=1,nzpmx)
            if (ios /= 0) then
               if (nrc(1) /= 0) nrc(1) = i
            endif
! send data from node 0
            call MPI_SEND(g,nnyzp,mreal,id,98,lgrp,ierr)
         enddo
! other nodes receive data from node 0
      else 
         call MPI_RECV(f,nnyzp,mreal,0,98,lgrp,istatus,ierr)
      endif
! check for error condition
      call PPIMAX(nrc,iwrk1,1)
      irc = nrc(1)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPWRVCDATA3(f,g,ndim,nzv,kxypd,kyzpd,iunit)
! this subroutine collects distributed periodic complex 2d vector data f
! and writes to a fortran unformatted file with spatial decomposition
! f = input data to be written
! g = scratch data
! ndim = first dimension of data array f
! nzv = second dimension of data array f
! kxypd = third dimension of data array f
! kyzpd = fourth dimension of data array f
! iunit = fortran unit number
! input: all
      implicit none
      integer, intent(in) :: ndim, nzv, kxypd, kyzpd, iunit
      complex, intent(in), dimension(ndim,nzv,kxypd,kyzpd) :: f
      complex, intent(inout), dimension(ndim,nzv,kxypd,kyzpd) :: g
! lgrp = current communicator
! mint = default datatype for integers
! mcplx = default datatype for complex type
! local data
      integer :: nvp, idproc, igo, nnxyp, id, i, j, k, l, n, ierr
      integer :: msid
      integer, dimension(lstat) :: istatus
      nnxyp = ndim*nzv*kxypd*kyzpd
      igo = 1
! this segment is used for shared memory computers
!     write (unit=iunit) ((((f(n,l,j,k),n=1,ndim),l=1,nzv),j=1,kxypd),  &
!    &k=1,kyzpd)
! this segment is used for mpi computers
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! determine the size of the group associated with a communicator
      call MPI_COMM_SIZE(lgrp,nvp,ierr)
! node 0 receives messages from other nodes
      if (idproc==0) then
! first write data for node 0
         write (unit=iunit) ((((f(n,l,j,k),n=1,ndim),l=1,nzv),j=1,kxypd)&
     &,k=1,kyzpd)
! then write data from remaining nodes
         do i = 2, nvp
         id = i - 1
! send go signal to sending node
         call MPI_SEND(igo,1,mint,id,98,lgrp,ierr)
         call MPI_IRECV(g,nnxyp,mcplx,id,99,lgrp,msid,ierr)
         call MPI_WAIT(msid,istatus,ierr)
         write (unit=iunit) ((((g(n,l,j,k),n=1,ndim),l=1,nzv),j=1,kxypd)&
     &,k=1,kyzpd)
         enddo
! other nodes send data to node 0 after receiving go signal
      else
         call MPI_IRECV(igo,1,mint,0,98,lgrp,msid,ierr)
         call MPI_WAIT(msid,istatus,ierr)
         call MPI_SEND(f,nnxyp,mcplx,0,99,lgrp,ierr)
      endif
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPRDVCDATA3(f,g,ndim,nzv,kxypd,kyzpd,iunit,irc)
! this subroutine reads periodic complex 2d vector data f from a fortran
! unformatted file and distributes it with spatial decomposition
! f = output data to be read
! g = scratch data
! ndim = first dimension of data array f
! nzv = second dimension of data array f
! kxypd = third dimension of data array f
! kyzpd = fourth dimension of data array f
! iunit = fortran unit number
! irc = error indicator
! input: all, output: f, irc
      implicit none
      integer, intent(in) :: ndim, nzv, kxypd, kyzpd, iunit
      integer, intent(inout) :: irc
      complex, intent(inout), dimension(ndim,nzv,kxypd,kyzpd) :: f, g
! lgrp = current communicator
! mcplx = default datatype for complex type
! local data
      integer :: nvp, idproc, nnxyp, id, i, j, k, l, n, ios, ierr
      integer, dimension(1) :: nrc, iwrk1
      integer, dimension(lstat) :: istatus
      nnxyp = ndim*nzv*kxypd*kyzpd
      nrc(1) = 0
! this segment is used for shared memory computers
!     read (unit=iunit,iostat=ios) ((((f(n,l,j,k),n=1,ndim),l=1,nzv),   &
!    &j=1,kxypd),k=1,kyzpd)
!     if (ios /= 0) nrc(1) = 1
! this segment is used for mpi computers
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! determine the size of the group associated with a communicator
      call MPI_COMM_SIZE(lgrp,nvp,ierr)
! node 0 receives messages from other nodes
      if (idproc==0) then
! first read data for node 0
         read (unit=iunit,iostat=ios) ((((f(n,l,j,k),n=1,ndim),l=1,nzv),&
     &j=1,kxypd),k=1,kyzpd)
         if (ios /= 0) nrc(1) = 1
! then read data on node 0 to send to remaining nodes
         do i = 2, nvp
            id = i - 1
            read (unit=iunit,iostat=ios) ((((g(n,l,j,k),n=1,ndim),      &
     &l=1,nzv),j=1,kxypd),k=1,kyzpd)
            if (ios /= 0) then
               if (nrc(1) /= 0) nrc(1) = i
            endif
! send data from node 0
            call MPI_SEND(g,nnxyp,mcplx,id,98,lgrp,ierr)
         enddo
! other nodes receive data from node 0
      else 
         call MPI_RECV(f,nnxyp,mcplx,0,98,lgrp,istatus,ierr)
      endif
! check for error condition
      call PPIMAX(nrc,iwrk1,1)
      irc = nrc(1)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPARTT3(partt,numtp,nvpy,nvpz,idimp,nprobt,irc)
! this subroutine collects distributed test particle data
! collects in the order of z processor varying fastest
! partt = tagged particle coordinates
! numtp = number of test particles found on this node
! nvpy/nvpz = number of real or virtual processors in y/z
! idimp = size of phase space = 7
! nprobt = number of test charges whose trajectories will be stored.
! irc = error indicator
! input: all, output: partt, irc
      implicit none
      integer, intent(in) :: numtp, nvpy, nvpz, idimp, nprobt
      integer, intent(inout) :: irc
      real, intent(inout), dimension(idimp,nprobt) :: partt
! lgrp = current communicator
! mreal = default datatype for reals
! local data
      integer :: idproc, noff, npbt, nntp, i, j, js, id, ltag, ierr
      integer :: msid
      integer, dimension(1) :: iwork
      integer, dimension(lstat) :: istatus
      nntp = idimp*numtp
      ltag = nprobt
      irc = 0
! this segment is used for mpi computers
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! node 0 receives messages from other nodes
      if (idproc==0) then
         noff = numtp + 1
         npbt = idimp*(nprobt - numtp)
         do j = 1, nvpy
         js = j - 1
         do i = 1, nvpz
         id = js + nvpy*(i - 1)
         if (id==0) cycle
         call MPI_IRECV(partt(1,noff),npbt,mreal,id,ltag,lgrp,msid,ierr)
         call MPI_WAIT(msid,istatus,ierr)
         call MPI_GET_COUNT(istatus,mreal,nntp,ierr)
         nntp = nntp/idimp
         noff = noff + nntp
         npbt = npbt - nntp
         enddo
         enddo
! incorrect number of trajectories received
         noff = noff - 1
         if (noff.ne.nprobt) irc = noff - 1
         iwork(1) = irc
         call PPBICAST(iwork,1)
         irc = iwork(1)
! other nodes send data to node 0
      else
         call MPI_SEND(partt,nntp,mreal,0,ltag,lgrp,ierr)
         call PPBICAST(iwork,1)
         irc = iwork(1)
      endif
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPADJFVS3(fvs,gvs,hvs,noff,nyzp,nmv,mvy,mvz,nvpy,nxb,  &
     &nyb,nzb,nybmx,nzbmx,nmvf,idds)
! for 3d code, this subroutine adjusts 3d velocity distribution, in
! different regions of space, so that partial regions have equal amounts
! of spatial grid points
! input: all except gvs, hvs, output: fvs, gvs, hvs
! fvs = spatially resolved distribution function
! gvs/hvs = scratch arrays
! noff(1:2) = lowermost global gridpoint in y/z in particle partition
! nyzp(1:2) = number of primary (complete) gridpoints in y/z
! mvy/mvz = number of grids in y/z for phase space aggregation
! nvpy = number of real or virtual processors in y
! nxb/nyb/nzb = number of segments in x/y/z for velocity distribution
! nybmx/nzbmx = maximum size of nyb/nzb across processors
! nmvf = first dimension of fvs
! idds = dimensionality of domain decomposition = 2
      implicit none
      integer, intent(in) :: nmv, mvy, mvz, nvpy
      integer, intent(in) :: nxb, nyb, nzb, nybmx, nzbmx, nmvf, idds
      real, dimension(nmvf,3,nxb,nybmx+1,nzb+1), intent(inout) :: fvs
      real, dimension(nmvf,3,nxb,nzbmx+1,2), intent(inout) :: gvs
      real, dimension(nmvf,3,nxb,nyb), intent(inout) :: hvs
      integer, dimension(idds), intent(in) :: noff, nyzp
! local data
      integer :: i, j, k, l, m, nps, idproc, nvp, ks, idm, ns, ne, id
      integer :: nmv21, ndata, mdata
      integer :: msid, ltag, ierr
      integer, dimension(lstat) :: istatus
      real, dimension(3) :: scale
      nmv21 = 2*nmv + 1
      nps = 3*nmvf*nxb
      ltag = 3*nmvf
! this segment is used for mpi computers
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! determine the size of the group associated with a communicator
      call MPI_COMM_SIZE(lgrp,nvp,ierr)
! ks = processor co-ordinates in z
      ks = idproc/nvpy
! collect partial data in y
      idm = nvpy*(ks + 1)
! calculate remainders
      ns = noff(1) - mvy*(noff(1)/mvy)
      ne = noff(1) + nyzp(1)
      ne = ne - mvy*(ne/mvy)
      ndata = nps*(nzbmx+1)
      mdata = nps*(nzb+1)
      ltag = ltag + 1
! buffer data in y
      do m = 1, nzb+1
      do k = 1, nxb
      do j = 1, 3
      do i = 1, nmvf
      gvs(i,j,k,m,1) = fvs(i,j,k,1,m)
      enddo
      enddo
      enddo
      enddo
! receive data from right if last region on this node has partial grid
      if (ne > 0) then
         id = idproc + 1
         if (id < idm) then
            call MPI_IRECV(gvs(1,1,1,1,2),ndata,mreal,id,ltag,lgrp,msid,&
     &ierr)
         endif
      endif
! send data to right if last region on previous node has partial grid
      if (ns > 0) then
         id = idproc - 1
         if (id >= 0) then
            call MPI_SEND(gvs(1,1,1,1,1),mdata,mreal,id,ltag,lgrp,ierr)
         endif
! save scale
         do j = 1, 3
         scale(j) = fvs(nmv21+1,j,1,1,1)
         enddo
! left shift data in y
         do m = 1, nzb+1
         do l = 1, nyb
         do k = 1, nxb
         do j = 1, 3
         do i = 1, nmvf
         fvs(i,j,k,l,m) = fvs(i,j,k,l+1,m)
         enddo
         enddo
         enddo
         enddo
         enddo
! restore scale
         do j = 1, 3
         fvs(nmv21+1,j,1,1,1) = scale(j)
         enddo
! zero out extra element
         do m = 1, nzb+1
         do k = 1, nxb
         do j = 1, 3
         do i = 1, nmvf
         fvs(i,j,k,nyb+1,m) = 0.0
         enddo
         enddo
         enddo
         enddo
      endif
! receive data from right if last region on this node has partial grid
      if (ne > 0) then
         id = idproc + 1
         if (id < idm) then
            call MPI_WAIT(msid,istatus,ierr)
            do m = 1, nzb+1
            do k = 1, nxb
            do j = 1, 3
            do i = 1, nmvf
            fvs(i,j,k,nyb,m) = fvs(i,j,k,nyb,m) + gvs(i,j,k,m,2)
            enddo
            enddo
            enddo
            enddo
         endif
      endif
! collect partial data in z
! calculate remainders
      ns = noff(2) - mvz*(noff(2)/mvz)
      ne = noff(2) + nyzp(2)
      ne = ne - mvz*(ne/mvz)
      ndata = nps*nyb
      ltag = ltag + 1
! receive data from above if last region on this node has partial grid
      if (ne > 0) then
         id = idproc + nvpy
         if (id < nvp) then
            call MPI_IRECV(hvs,ndata,mreal,id,ltag,lgrp,msid,ierr)
         endif
      endif
! send data to above if last region on previous node has partial grid
      if (ns > 0) then
         id = idproc - nvpy
         if (id >= 0) then
            call MPI_SEND(fvs,ndata,mreal,id,ltag,lgrp,ierr)
         endif
! save scale
         do j = 1, 3
         scale(j) = fvs(nmv21+1,j,1,1,1)
         enddo
! left shift data in z
         do m = 1, nzb
         do l = 1, nyb
         do k = 1, nxb
         do j = 1, 3
         do i = 1, nmvf
         fvs(i,j,k,l,m) = fvs(i,j,k,l,m+1)
         enddo
         enddo
         enddo
         enddo
         enddo
! restore scale
         do j = 1, 3
         fvs(nmv21+1,j,1,1,1) = scale(j)
         enddo
! zero out extra element
         do l = 1, nyb
         do k = 1, nxb
         do j = 1, 3
         do i = 1, nmvf
         fvs(i,j,k,l,nzb+1) = 0.0
         enddo
         enddo
         enddo
         enddo
      endif
! receive data from above if last region on this node has partial grid
      if (ne > 0) then
         id = idproc + nvpy
         if (id < nvp) then
            call MPI_WAIT(msid,istatus,ierr)
            do l = 1, nyb
            do k = 1, nxb
            do j = 1, 3
            do i = 1, nmvf
            fvs(i,j,k,l,nzb) = fvs(i,j,k,l,nzb) + hvs(i,j,k,l)
            enddo
            enddo
            enddo
            enddo
         endif
      endif
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPWRNCOMP3(nyp,nzp,nvpy,nvpz,iunit)
! this subroutine collects distributed non-uniform partition information
! and writes to a fortran unformatted file
! nyp/nzp = actual data written for third/fourth dimension
! nvpy/nvpz = number of real or virtual processors in y/z
! iunit = fortran unit number
! input: all
      implicit none
      integer, intent(in) :: nyp, nzp, nvpy, nvpz, iunit
! lgrp = current communicator
! mint = default datatype for integers
! local data
      integer :: i, nvp, idproc, id, ierr
      integer, dimension(2) :: nyzp(2)
      integer, dimension(lstat) :: istatus
      nyzp(1) = nyp; nyzp(2) = nzp
! this segment is used for shared memory computers
!     write (unit=iunit) nvpy, nvpz, nyp, nzp
! this segment is used for mpi computers
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! determine the size of the group associated with a communicator
      call MPI_COMM_SIZE(lgrp,nvp,ierr)
! node 0 receives messages from other nodes
      if (idproc==0) then
! first write data for node 0
         write (unit=iunit) nvpy, nvpz
         write (unit=iunit) nyzp
! then write data from remaining nodes
         do i = 2, nvp
         id = i - 1
         call MPI_RECV(nyzp,2,mint,id,97,lgrp,istatus,ierr)
         write (unit=iunit) nyzp
         enddo
! other nodes send data to node 0
      else
         call MPI_SEND(nyzp,2,mint,0,97,lgrp,ierr)
      endif
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPWRVNDATA3(f,g,ndim,nxv,nyp,nzp,nypmx,nzpmx,iunit)
! this subroutine collects distributed periodic real 3d vector
! non-uniform data f and writes to a fortran unformatted file
! f = input data to be written
! g = scratch data
! ndim = first dimension of data array f
! nxv = second dimension of data array f
! nyp/nzp = actual data written for third/fourth dimension
! nypmx+1 = third dimension of data array f and g
! nzpmx = fourth dimension of data array g
! iunit = fortran unit number
! input: all
      implicit none
      integer, intent(in) :: ndim, nxv, nyp, nzp, nypmx, nzpmx
      integer, intent(in) :: iunit
      real, intent(in), dimension(ndim,nxv,nypmx+1,nzp+1) :: f
      real, intent(inout), dimension(ndim,nxv,nypmx+1,nzpmx) :: g
! lgrp = current communicator
! mint = default datatype for integers
! mreal = default datatype for reals
! local data
      integer :: i, j, k, l, n
      integer :: nvp, idproc, id, nps, mps, nnxyv, nnyzp, nnyzpx
      integer :: msid, ierr
      integer, dimension(lstat) :: istatus
      nnxyv = ndim*nxv*(nypmx + 1)
      nnyzp = nnxyv*nzp
      nnyzpx = nnxyv*nzpmx
! this segment is used for shared memory computers
!     write (unit=iunit) ((((f(n,j,k,l),n=1,ndim),j=1,nxv),k=1,nyp),    &
!    &l=1,nzp)
! this segment is used for mpi computers
! determine the rank of the calling process in the communicator
      call MPI_COMM_RANK(lgrp,idproc,ierr)
! determine the size of the group associated with a communicator
      call MPI_COMM_SIZE(lgrp,nvp,ierr)
! node 0 receives messages from other nodes
      if (idproc==0) then
! first write data for node 0
         write (unit=iunit) ((((f(n,j,k,l),n=1,ndim),j=1,nxv),k=1,nyp), &
     &l=1,nzp)
! then write data from remaining nodes
         do i = 2, nvp
         id = i - 1
         call MPI_RECV(nps,1,mint,id,98,lgrp,istatus,ierr)
         call MPI_IRECV(g,nnyzpx,mreal,id,99,lgrp,msid,ierr)
         call MPI_WAIT(msid,istatus,ierr)
         call MPI_GET_COUNT(istatus,mreal,mps,ierr)
         mps = mps/nnxyv
         write (unit=iunit) ((((g(n,j,k,l),n=1,ndim),j=1,nxv),k=1,nps), &
     &l=1,mps)
         enddo
! other nodes send data to node 0
      else
         call MPI_SEND(nyp,1,mint,0,98,lgrp,ierr)
         call MPI_SEND(f,nnyzp,mreal,0,99,lgrp,ierr)
      endif
      end subroutine
!
      end module
!
! Make functions callable by Fortran77
!
!-----------------------------------------------------------------------
      subroutine PPINIT2(idproc,nvp)
      use mpplib3, only: SUB => PPINIT2
      implicit none
      integer, intent(inout) :: idproc, nvp
      call SUB(idproc,nvp)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPEXIT
      use mpplib3, only: SUB => PPEXIT
      implicit none
      call SUB()
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPABORT
      use mpplib3, only: SUB => PPABORT
      implicit none
      call SUB()
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PWTIMERA(icntrl,time,dtime)
      use mpplib3, only: SUB => PWTIMERA
      implicit none
      integer, intent(in) :: icntrl
      real, intent(inout) :: time
      double precision, intent(inout) :: dtime
      call SUB(icntrl,time,dtime)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPCOMM_T(nvpy,nvpz)
      use mpplib3, only: SUB => PPCOMM_T
      integer, intent(in) :: nvpy, nvpz
      call SUB(nvpy,nvpz)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPSUM(f,g,nxp)
      use mpplib3, only: SUB => PPSUM
      implicit none
      integer, intent(in) :: nxp
      real, dimension(nxp), intent(inout) :: f, g
      call SUB(f,g,nxp)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPDSUM(f,g,nxp)
      use mpplib3, only: SUB => PPDSUM
      implicit none
      integer, intent(in) :: nxp
      double precision, dimension(nxp), intent(inout) :: f, g
      call SUB(f,g,nxp)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPMAX(f,g,nxp)
      use mpplib3, only: SUB => PPMAX
      implicit none
      integer, intent(in) :: nxp
      real, dimension(nxp), intent(inout) :: f, g
      call SUB(f,g,nxp)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPIMAX(if,ig,nxp)
      use mpplib3, only: SUB => PPIMAX
      implicit none
      integer, intent(in) :: nxp
      integer, dimension(nxp), intent(inout) :: if, ig
      call SUB(if,ig,nxp)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPDMAX(f,g,nxp)
      use mpplib3, only: SUB => PPDMAX
      implicit none
      integer, intent(in) :: nxp
      double precision, dimension(nxp), intent(inout) :: f, g
      call SUB(f,g,nxp)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPDSCAN(f,g,nxp)
      use mpplib3, only: SUB => PPDSCAN
      implicit none
      integer, intent(in) :: nxp
      double precision, dimension(nxp), intent(inout) :: f, g
      call SUB(f,g,nxp)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPDSCAN_T(f,g,nxp)
      use mpplib3, only: SUB => PPDSCAN_T
      implicit none
      integer, intent(in) :: nxp
      double precision, dimension(nxp), intent(inout) :: f, g
      call SUB(f,g,nxp)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPBICAST(if,nxp)
      use mpplib3, only: SUB => PPBICAST
      implicit none
      integer, intent(in) :: nxp
      integer, dimension(nxp), intent(inout) :: if
      call SUB(if,nxp)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPBDCAST(f,nxp)
      use mpplib3, only: SUB => PPBDCAST
      implicit none
      integer, intent(in) :: nxp
      double precision, dimension(nxp), intent(inout) :: f
      call SUB(f,nxp)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPBICASTZ(if,nxp,nvpy,nvpz)
      use mpplib3, only: SUB => PPBICASTZ
      implicit none
      integer, intent(in) :: nxp, nvpy, nvpz
      real, dimension(nxp), intent(inout) :: if
      call SUB(if,nxp,nvpy,nvpz)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPBICASTZR(if,nxp,nvpy,nvpz)
      use mpplib3, only: SUB => PPBICASTZR
      implicit none
      integer, intent(in) :: nxp, nvpy, nvpz
      real, dimension(nxp), intent(inout) :: if
      call SUB(if,nxp,nvpy,nvpz)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPISHFTR2(if,ig,nxp,nvpy,nvpz)
      use mpplib3, only: SUB => PPISHFTR2
      implicit none
      integer, intent(in) :: nxp, nvpy, nvpz
      integer, dimension(nxp,2), intent(inout) :: if, ig
      call SUB(if,ig,nxp,nvpy,nvpz)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPNCGUARD32L(f,scs,nyzp,kstrt,nvpy,nvpz,nxv,nypmx,nzpmx&
     &,idds)
      use mpplib3, only: SUB => PPNCGUARD32L
      implicit none
      integer, intent(in) :: kstrt, nvpy, nvpz, nxv, nypmx, nzpmx, idds
      real, dimension(nxv,nypmx,nzpmx), intent(inout) :: f
      real, dimension(nxv,nzpmx,2), intent(inout) :: scs
      integer, dimension(idds), intent(in) :: nyzp
      call SUB(f,scs,nyzp,kstrt,nvpy,nvpz,nxv,nypmx,nzpmx,idds)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPNAGUARD32L(f,scs,scr,nyzp,kstrt,nvpy,nvpz,nx,nxv,    &
     &nypmx,nzpmx,idds)
      use mpplib3, only: SUB => PPNAGUARD32L
      implicit none
      integer, intent(in) :: kstrt, nvpy, nvpz, nx, nxv, nypmx, nzpmx
      integer, intent(in) :: idds
      real, dimension(nxv,nypmx,nzpmx), intent(inout) :: f
      real, dimension(nxv,nzpmx,2), intent(inout) :: scs
      real, dimension(nxv,nypmx), intent(inout) :: scr
      integer, dimension(idds), intent(in) :: nyzp
      call SUB(f,scs,scr,nyzp,kstrt,nvpy,nvpz,nx,nxv,nypmx,nzpmx,idds)
      end subroutine
!
!-----------------------------------------------------------------------
       subroutine PPNACGUARD32L(f,scs,scr,nyzp,ndim,kstrt,nvpy,nvpz,nx,  &
     &nxv,nypmx,nzpmx,idds)
      use mpplib3, only: SUB => PPNACGUARD32L
      implicit none
      integer, intent(in) :: ndim, kstrt, nvpy, nvpz, nx, nxv
      integer, intent(in) :: nypmx, nzpmx, idds
      real, dimension(ndim,nxv,nypmx,nzpmx), intent(inout) :: f
      real, dimension(ndim,nxv,nzpmx,2), intent(inout) :: scs
      real, dimension(ndim,nxv,nypmx), intent(inout) :: scr
      integer, dimension(idds), intent(in) :: nyzp
      call SUB(f,scs,scr,nyzp,ndim,kstrt,nvpy,nvpz,nx,nxv,nypmx,nzpmx,  &
     &idds)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPFYMOVE32(f,g,h,noff,nyzp,noffs,nyzps,noffd,nyzpd,    &
     &isign,kyp,kzp,ny,nz,kstrt,nvpy,nvpz,nxv,nypmx,nzpmx,idds,mter,ierr&
     &)
      use mpplib3, only: SUB => PPFYMOVE32
      implicit none
      integer, intent(in) :: isign, kyp, kzp, ny, nz, kstrt, nvpy, nvpz
      integer, intent(in) :: nxv, nypmx, nzpmx, idds
      integer, intent(inout) :: mter, ierr
      real, dimension(nxv,nypmx,nzpmx), intent(inout) :: f
      real, dimension(nxv,nypmx*nzpmx) :: g, h
      integer, dimension(idds), intent(in) :: noff, nyzp
      integer, dimension(idds), intent(inout) :: noffs, nyzps
      integer, dimension(idds), intent(inout) :: noffd, nyzpd
      call SUB(f,g,h,noff,nyzp,noffs,nyzps,noffd,nyzpd,isign,kyp,kzp,ny,&
     &nz,kstrt,nvpy,nvpz,nxv,nypmx,nzpmx,idds,mter,ierr)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPFZMOVE32(f,g,h,noff,nyzp,noffs,nyzps,noffd,nyzpd,    &
     &isign,kyp,kzp,ny,nz,kstrt,nvpy,nvpz,nxv,nypmx,nzpmx,idds,mter,ierr&
     &)
      use mpplib3, only: SUB => PPFZMOVE32
      implicit none
      integer, intent(in) :: isign, kyp, kzp, ny, nz, kstrt, nvpy, nvpz
      integer, intent(in) :: nxv, nypmx, nzpmx, idds
      integer, intent(inout) :: mter, ierr
      real, dimension(nxv,nypmx,nzpmx), intent(inout) :: f
      real, dimension(nxv,nypmx*nzpmx) :: g, h
      integer, dimension(idds), intent(in) :: noff, nyzp
      integer, dimension(idds), intent(inout) :: noffs, nyzps
      integer, dimension(idds), intent(inout) :: noffd, nyzpd
      call SUB(f,g,h,noff,nyzp,noffs,nyzps,noffd,nyzpd,isign,kyp,kzp,ny,&
     &nz,kstrt,nvpy,nvpz,nxv,nypmx,nzpmx,idds,mter,ierr)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPTPOS3A(f,g,s,t,nx,ny,nz,kxyp,kyp,kzp,kstrt,nvpy,nxv, &
     &nyv,kxypd,kypd,kzpd)
      use mpplib3, only: SUB => PPTPOS3A
      implicit none
      integer, intent(in) :: nx, ny, nz, kxyp, kyp, kzp, kstrt, nvpy
      integer, intent(in) :: nxv, nyv, kxypd, kypd, kzpd
      complex, dimension(nxv,kypd,kzpd), intent(in) :: f
      complex, dimension(nyv,kxypd,kzpd), intent(inout) :: g
      complex, dimension(kxyp*kyp*kzp), intent(inout) :: s, t
      call SUB(f,g,s,t,nx,ny,nz,kxyp,kyp,kzp,kstrt,nvpy,nxv,nyv,kxypd,  &
     &kypd,kzpd)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPTPOS3B(g,h,s,t,nx,ny,nz,kxyp,kyzp,kzp,kstrt,nvpy,nvpz&
     &,nyv,nzv,kxypd,kyzpd,kzpd)
      use mpplib3, only: SUB => PPTPOS3B
      implicit none
      integer, intent(in) :: nx, ny, nz, kxyp, kyzp, kzp, kstrt
      integer, intent(in) :: nvpy, nvpz, nyv, nzv, kxypd, kyzpd, kzpd
      complex, dimension(nyv,kxypd,kzpd), intent(inout) :: g
      complex, dimension(nzv,kxypd,kyzpd), intent(inout) :: h
      complex, dimension(kyzp*kxyp*kzp), intent(inout) :: s, t
      call SUB(g,h,s,t,nx,ny,nz,kxyp,kyzp,kzp,kstrt,nvpy,nvpz,nyv,nzv,  &
     &kxypd,kyzpd,kzpd)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPNTPOS3A(f,g,s,t,nx,ny,nz,kxyp,kyp,kzp,kstrt,nvpy,ndim&
     &,nxv,nyv,kxypd,kypd,kzpd)
      use mpplib3, only: SUB => PPNTPOS3A
      implicit none
      integer, intent(in) :: nx, ny, nz, kxyp, kyp, kzp, kstrt, nvpy
      integer, intent(in) :: ndim, nxv, nyv, kxypd, kypd, kzpd
      complex, dimension(ndim,nxv,kypd,kzpd), intent(in) :: f
      complex, dimension(ndim,nyv,kxypd,kzpd), intent(inout) :: g
      complex, dimension(ndim,kxyp*kyp*kzp), intent(inout) :: s, t
      call SUB(f,g,s,t,nx,ny,nz,kxyp,kyp,kzp,kstrt,nvpy,ndim,nxv,nyv,   &
     &kxypd,kypd,kzpd)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPNTPOS3B(g,h,s,t,nx,ny,nz,kxyp,kyzp,kzp,kstrt,nvpy,   &
     &nvpz,ndim,nyv,nzv,kxypd,kyzpd,kzpd)
      use mpplib3, only: SUB => PPNTPOS3B
      implicit none
      integer, intent(in) :: nx, ny, nz, kxyp, kyzp, kzp, kstrt, nvpy
      integer, intent(in) :: nvpz, ndim, nyv, nzv, kxypd, kyzpd, kzpd
      complex, dimension(ndim,nyv,kxypd,kzpd), intent(inout) :: g
      complex, dimension(ndim,nzv,kxypd,kyzpd), intent(inout) :: h
      complex, dimension(ndim,kyzp*kxyp*kzp), intent(inout) :: s, t
      call SUB(g,h,s,t,nx,ny,nz,kxyp,kyzp,kzp,kstrt,nvpy,nvpz,ndim,nyv, &
     &nzv,kxypd,kyzpd,kzpd)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPMOVE32(part,edges,npp,sbufr,sbufl,rbufr,rbufl,ihole, &
     &ny,nz,kstrt,nvpy,nvpz,nc,idimp,npmax,idps,nbmax,ntmax,info)
      use mpplib3, only: SUB => PPMOVE32
      implicit none
      integer, intent(in) :: ny, nz, kstrt, nvpy, nvpz, nc, idimp, npmax
      integer, intent(in) :: idps, nbmax, ntmax
      integer, intent(inout) :: npp
      real, dimension(idimp,npmax), intent(inout) :: part
      real, dimension(idps), intent(in) :: edges
      real, dimension(idimp,nbmax), intent(inout) :: sbufl, sbufr
      real, dimension(idimp,nbmax), intent(inout) :: rbufl, rbufr
      integer, dimension(ntmax+1,2), intent(inout) :: ihole
      integer, dimension(7), intent(inout) :: info
      call SUB(part,edges,npp,sbufr,sbufl,rbufr,rbufl,ihole,ny,nz,kstrt,&
     &nvpy,nvpz,nc,idimp,npmax,idps,nbmax,ntmax,info)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPPMOVE32(sbufr,sbufl,rbufr,rbufl,ncll,nclr,mcll,mclr, &
     &mcls,kstrt,nvpy,nvpz,idimp,nbmax,mx1,myp1,mzp1,mxzyp1,irc)
      use mpplib3, only: SUB => PPPMOVE32
      implicit none
      integer, intent(in) :: kstrt, nvpy, nvpz, idimp, nbmax
      integer, intent(in) :: mx1, myp1, mzp1, mxzyp1
      integer, intent(inout) :: irc
      real, dimension(idimp,nbmax,2), intent(in) :: sbufr, sbufl
      real, dimension(idimp,nbmax,2), intent(inout) :: rbufr, rbufl
      integer, dimension(3,mxzyp1,3,2), intent(inout) :: ncll, nclr
      integer, dimension(3,mxzyp1,3,2), intent(inout) :: mcll, mclr
      integer, dimension(3,mx1+1,4), intent(inout) :: mcls
      call SUB(sbufr,sbufl,rbufr,rbufl,ncll,nclr,mcll,mclr,mcls,kstrt,  &
     &nvpy,nvpz,idimp,nbmax,mx1,myp1,mzp1,mxzyp1,irc)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPWRITE32(f,g,nx,ny,nz,kyp,kzp,nvpy,nxv,nypmx,nzpmx,   &
     &iunit,nrec)
      use mpplib3, only: SUB => PPWRITE32
      implicit none
      integer, intent(in) :: nx, ny, nz, kyp, kzp, nvpy, nxv
      integer, intent(in) :: nypmx, nzpmx, iunit
      integer, intent(inout) :: nrec
      real, intent(in), dimension(nxv,nypmx,nzpmx) :: f
      real, intent(inout), dimension(nxv,nypmx,nzpmx) :: g
      call SUB(f,g,nx,ny,nz,kyp,kzp,nvpy,nxv,nypmx,nzpmx,iunit,nrec)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPREAD32(f,g,nx,ny,nz,kyp,kzp,nvpy,nxv,nypmx,nzpmx,    &
     &iunit,nrec,irc)
      use mpplib3, only: SUB => PPREAD32
      implicit none
      integer, intent(in) :: nx, ny, nz, kyp, kzp, nvpy, nxv
      integer, intent(in) :: nypmx, nzpmx, iunit
      integer, intent(inout) :: nrec, irc
      real, intent(inout), dimension(nxv,nypmx,nzpmx) :: f, g
      call SUB(f,g,nx,ny,nz,kyp,kzp,nvpy,nxv,nypmx,nzpmx,iunit,nrec,irc)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPVWRITE32(f,g,nx,ny,nz,kyp,kzp,nvpy,ndim,nxv,nypmx,   &
     &nzpmx,iunit,nrec)
      use mpplib3, only: SUB => PPVWRITE32
      implicit none
      integer, intent(in) :: nx, ny, nz, kyp, kzp, nvpy, ndim, nxv
      integer, intent(in) :: nypmx, nzpmx, iunit
      integer, intent(inout) :: nrec
      real, intent(in), dimension(ndim,nxv,nypmx,nzpmx) :: f
      real, intent(inout), dimension(ndim,nxv,nypmx,nzpmx) :: g
      call SUB(f,g,nx,ny,nz,kyp,kzp,nvpy,ndim,nxv,nypmx,nzpmx,iunit,nrec&
     &)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPVREAD32(f,g,nx,ny,nz,kyp,kzp,nvpy,ndim,nxv,nypmx,    &
     &nzpmx,iunit,nrec,irc)
      use mpplib3, only: SUB => PPVREAD32
      implicit none
      integer, intent(in) :: nx, ny, nz, kyp, kzp, nvpy, ndim, nxv
      integer, intent(in) :: nypmx, nzpmx, iunit
      integer, intent(inout) :: nrec, irc
      real, intent(inout), dimension(ndim,nxv,nypmx,nzpmx) :: f, g
      call SUB(f,g,nx,ny,nz,kyp,kzp,nvpy,ndim,nxv,nypmx,nzpmx,iunit,nrec&
     &,irc)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPWRPART3(part,npp,idimp,npmax,iunit,iscr)
      use mpplib3, only: SUB => PPWRPART3
      implicit none
      integer, intent(in) :: npp, idimp, npmax, iunit, iscr
      real, intent(inout), dimension(idimp,npmax) :: part
      call SUB(part,npp,idimp,npmax,iunit,iscr)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPRDPART3(part,npp,idimp,npmax,iunit,iscr,irc)
      use mpplib3, only: SUB => PPRDPART3
      implicit none
      integer, intent(in) :: idimp, npmax, iunit, iscr
      integer, intent(inout) :: npp, irc
      real, intent(inout), dimension(idimp,npmax) :: part
      call SUB(part,npp,idimp,npmax,iunit,iscr,irc)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPWRDATA3(f,g,nxv,nypmx,nzpmx,iunit)
      use mpplib3, only: SUB => PPWRDATA3
      implicit none
      integer, intent(in) :: nxv, nypmx, nzpmx, iunit
      real, intent(in), dimension(nxv,nypmx,nzpmx) :: f
      real, intent(inout), dimension(nxv,nypmx,nzpmx) :: g
      call SUB(f,g,nxv,nypmx,nzpmx,iunit)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPRDDATA3(f,g,nxv,nypmx,nzpmx,iunit,irc)
      use mpplib3, only: SUB => PPRDDATA3
      implicit none
      integer, intent(in) :: nxv, nypmx, nzpmx, iunit
      integer, intent(inout) :: irc
      real, intent(inout), dimension(nxv,nypmx,nzpmx) :: f, g
      call SUB(f,g,nxv,nypmx,nzpmx,iunit,irc)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPWRVCDATA3(f,g,ndim,nzv,kxypd,kyzpd,iunit)
      use mpplib3, only: SUB => PPWRVCDATA3
      implicit none
      integer, intent(in) :: ndim, nzv, kxypd, kyzpd, iunit
      complex, intent(in), dimension(ndim,nzv,kxypd,kyzpd) :: f
      complex, intent(inout), dimension(ndim,nzv,kxypd,kyzpd) :: g
      call SUB(f,g,ndim,nzv,kxypd,kyzpd,iunit)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPRDVCDATA3(f,g,ndim,nzv,kxypd,kyzpd,iunit,irc)
      use mpplib3, only: SUB => PPRDVCDATA3
      implicit none
      integer, intent(in) :: ndim, nzv, kxypd, kyzpd, iunit
      integer, intent(inout) :: irc
      complex, intent(inout), dimension(ndim,nzv,kxypd,kyzpd) :: f, g
      call SUB(f,g,ndim,nzv,kxypd,kyzpd,iunit,irc)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPWRVDATA3(f,g,ndim,nxv,nypmx,nzpmx,iunit)
      use mpplib3, only: SUB => PPWRVDATA3
      implicit none
      integer, intent(in) :: ndim, nxv, nypmx, nzpmx, iunit
      real, intent(in), dimension(ndim,nxv,nypmx,nzpmx) :: f
      real, intent(inout), dimension(ndim,nxv,nypmx,nzpmx) :: g
      call SUB(f,g,ndim,nxv,nypmx,nzpmx,iunit)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPRDVDATA3(f,g,ndim,nxv,nypmx,nzpmx,iunit,irc)
      use mpplib3, only: SUB => PPRDVDATA3
      implicit none
      integer, intent(in) :: ndim, nxv, nypmx, nzpmx, iunit
      integer, intent(inout) :: irc
      real, intent(inout), dimension(ndim,nxv,nypmx,nzpmx) :: f, g
      call SUB(f,g,ndim,nxv,nypmx,nzpmx,iunit,irc)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPARTT3(partt,numtp,nvpy,nvpz,idimp,nprobt,irc)
      use mpplib3, only: SUB => PPARTT3
      implicit none
      integer, intent(in) :: numtp, nvpy, nvpz, idimp, nprobt
      integer, intent(inout) :: irc
      real, intent(inout), dimension(idimp,nprobt) :: partt
      call SUB(partt,numtp,nvpy,nvpz,idimp,nprobt,irc)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPADJFVS3(fvs,gvs,hvs,noff,nyzp,nmv,mvy,mvz,nvpy,nxb,  &
     &nyb,nzb,nybmx,nzbmx,nmvf,idds)
      use mpplib3, only: SUB => PPADJFVS3
      implicit none
      integer, intent(in) :: nmv, mvy, mvz, nvpy
      integer, intent(in) :: nxb, nyb, nzb, nybmx, nzbmx, nmvf, idds
      real, dimension(nmvf,3,nxb,nyb+1,nzb+1), intent(inout) :: fvs
      real, dimension(nmvf,3,nxb,nzbmx+1,2), intent(inout) :: gvs
      real, dimension(nmvf,3,nxb,nyb), intent(inout) :: hvs
      integer, dimension(idds), intent(in) :: noff, nyzp
      call SUB(fvs,gvs,hvs,noff,nyzp,nmv,mvy,mvz,nvpy,nxb,nyb,nzb,nybmx,&
     &nzbmx,nmvf,idds)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPWRNCOMP3(nyp,nzp,nvpy,nvpz,iunit)
      use mpplib3, only: SUB => PPWRNCOMP3
      implicit none
      integer, intent(in) :: nyp, nzp, nvpy, nvpz, iunit
      call SUB(nyp,nzp,nvpy,nvpz,iunit)
      end subroutine
!
!-----------------------------------------------------------------------
      subroutine PPWRVNDATA3(f,g,ndim,nxv,nyp,nzp,nypmx,nzpmx,iunit)
      use mpplib3, only: SUB => PPWRVNDATA3
      implicit none
      integer, intent(in) :: ndim, nxv, nyp, nzp, nypmx, nzpmx, iunit
      real, intent(in), dimension(ndim,nxv,nyp,nzp) :: f
      real, intent(inout), dimension(ndim,nxv,nypmx,nzpmx) :: g
      call SUB(f,g,ndim,nxv,nyp,nzp,nypmx,nzpmx,iunit)
      end subroutine
