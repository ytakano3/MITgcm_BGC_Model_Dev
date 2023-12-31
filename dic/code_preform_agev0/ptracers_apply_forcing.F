#include "PTRACERS_OPTIONS.h"

CBOP
C !ROUTINE: PTRACERS_APPLY_FORCING

C !INTERFACE: ==========================================================
      SUBROUTINE PTRACERS_APPLY_FORCING(
     U                    gPtracer,
     I                    surfForcPtr,
     I                    iMin,iMax,jMin,jMax, k, bi, bj,
     I                    iTracer, myTime, myIter, myThid )

C !DESCRIPTION:
C     Apply passive tracer forcing, i.e., sources and sinks of tracer,
C      by adding forcing terms to the tendency array

C !USES: ===============================================================
      IMPLICIT NONE
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS_PARAMS.h"
#include "PTRACERS_FIELDS.h"

C !INPUT PARAMETERS: ===================================================
C  gPtracer             :: the tendency array
C  surfForcPtr          :: surface forcing term
C  iMin iMax jMin jMax  :: working range of tile for applying forcing
C  k                    :: vertical level number
C  bi,bj                :: tile indices
C  iTracer              :: tracer number
C  myIter               :: time-step number
C  myTime               :: model time
C  myThid               :: thread number
      _RL gPtracer   (1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL surfForcPtr(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      INTEGER iMin,iMax,jMin,jMax
      INTEGER k, bi,bj, iTracer
      _RL myTime
      INTEGER myIter
      INTEGER myThid

C !OUTPUT PARAMETERS: ==================================================
C  gPtracer       :: updates tendency array

#ifdef ALLOW_PTRACERS

C !LOCAL VARIABLES: ====================================================
C  i,j            :: loop indices
      INTEGER i,j
C     number of surface interface layer
      INTEGER kSurface
CEOP

      IF ( fluidIsAir ) THEN
       kSurface = 0
      ELSEIF ( usingZCoords .AND. useShelfIce ) THEN
       kSurface = -1
      ELSEIF ( usingPCoords ) THEN
       kSurface = Nr
      ELSE
       kSurface = 1
      ENDIF

C--   Surface forcing term surfForcPtr is previously computed by
C     PTRACERS_FORCING_SURF (and stored as surfaceForcingPTr)
C     because it is needed by KPP_TRANSPORT_PTR.

#ifdef ALLOW_GCHEM
      IF ( useGCHEM ) THEN
        CALL GCHEM_ADD_TENDENCY(
     U                 gPtracer,
     I                 iMin,iMax,jMin,jMax, k, bi, bj,
     I                 iTracer, myTime, myIter, myThid )
      ENDIF
#endif /* ALLOW_GCHEM */

      IF ( k .EQ. kSurface ) THEN
c      DO j=jMin,jMax
c       DO i=iMin,iMax
       DO j=0,sNy+1
        DO i=0,sNx+1
          gPtracer(i,j) = gPtracer(i,j)
     &                  + surfForcPtr(i,j)
     &                   *recip_drF(k)*recip_hFacC(i,j,k,bi,bj)
        ENDDO
       ENDDO
      ELSEIF ( kSurface.EQ.-1 ) THEN
       DO j=0,sNy+1
        DO i=0,sNx+1
         IF ( kSurfC(i,j,bi,bj).EQ.k ) THEN
          gPtracer(i,j) = gPtracer(i,j)
     &                  + surfForcPtr(i,j)
     &                   *recip_drF(k)*recip_hFacC(i,j,k,bi,bj)
         ENDIF
        ENDDO
       ENDDO
      ENDIF

      IF (PTRACERS_linFSConserve(iTracer)) THEN
       DO j=0,sNy+1
        DO i=0,sNx+1
         IF ( kSurfC(i,j,bi,bj).EQ.k ) THEN
            gPtracer(i,j) = gPtracer(i,j)
     &           +meanSurfCorPTr(iTracer)*recip_drF(k)
     &           *_recip_hFacC(i,j,k,bi,bj)
         ENDIF
        ENDDO
       ENDDO
      ENDIF

      IF (iTracer .EQ. 11 ) THEN

       IF (k .EQ. kSurface ) THEN
        DO j=0,sNy+1
         DO i=0,sNx+1
          Ptracer(i,j,k,bi,bj,11) = 0.0
         ENDDO
        ENDDO
       ELSE
        DO j=0,sNy+1
         DO i=0,sNx+1
          gPtracer(i,j) = gPtracer(i,j)
     &         + 1.0*maskC(i,j,k,bi,bj)
     &         /(86400.00*360.0)
         ENDDO
        ENDDO
       ENDIF

      ENDIF               
C Note (Y.T): Ideal age tracer as tracer #11 (iTracer = 11)
C           : turn on the preformed tracer "ALLOW_PREFORM"
C           : in DIC_OPTIONS.h
C           : One year is 360 days in this setting
C    (Check): do we need to define as an 11th tracer in DIC package?

#ifdef ALLOW_RBCS
      IF ( useRBCS ) THEN
         CALL RBCS_ADD_TENDENCY(
     U                 gPtracer,
     I                 k, bi, bj, iTracer+2,
     I                 myTime, myIter, myThid )
      ENDIF
#endif /* ALLOW_RBCS */

#endif /* ALLOW_PTRACERS */

      RETURN
      END
