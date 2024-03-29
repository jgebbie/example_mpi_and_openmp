/*
  "Hello World" MPI Test Program
 */
#include <mpi.h>
#include <omp.h>
#include <stdio.h>
#include <string.h>

#define BUFSIZE 128
#define TAG 0

int main ( int argc, char* argv[] )
{
    char idstr[32];
    char buff[BUFSIZE];
    int numprocs;
    int myid;
    int i;
    MPI_Status stat;

    MPI_Init ( &argc, &argv ); /* all MPI programs start with MPI_Init; all 'N' processes exist thereafter */
    MPI_Comm_size ( MPI_COMM_WORLD, &numprocs ); /* find out how big the SPMD world is */
    MPI_Comm_rank ( MPI_COMM_WORLD, &myid ); /* and this processes' rank is */

    /* At this point, all programs are running equivalently, the rank distinguishes
       the roles of the programs in the SPMD model, with rank 0 often used specially... */
    if ( myid == 0 ) {
        printf ( "%d: We have %d processors\n", myid, numprocs );
        for ( i = 1; i < numprocs; i++ ) {
            sprintf ( buff, "Hello %d! ", i );
            MPI_Send ( buff, BUFSIZE, MPI_CHAR, i, TAG, MPI_COMM_WORLD );
        }
        for ( i = 1; i < numprocs; i++ ) {
            MPI_Recv ( buff, BUFSIZE, MPI_CHAR, i, TAG, MPI_COMM_WORLD, &stat );
            printf ( "%d: %s\n", myid, buff );
        }
    } else {
        /* receive from rank 0: */
        MPI_Recv ( buff, BUFSIZE, MPI_CHAR, 0, TAG, MPI_COMM_WORLD, &stat );

        {
            int th_id, nthreads;
            #pragma omp parallel private(th_id) shared(nthreads)
            {
                th_id = omp_get_thread_num();
                #pragma omp critical
                {
                    printf ( "Hello World from thread %d\n", th_id );
                }
                #pragma omp barrier

                #pragma omp master
                {
                    nthreads = omp_get_num_threads();
                    printf ( "There are %d threads\n", nthreads );
                }
            }
        }

        sprintf ( idstr, "Processor %d ", myid );
        strncat ( buff, idstr, BUFSIZE - 1 );
        strncat ( buff, "reporting for duty\n", BUFSIZE - 1 );
        /* send to rank 0: */
        MPI_Send ( buff, BUFSIZE, MPI_CHAR, 0, TAG, MPI_COMM_WORLD );
    }

    MPI_Finalize(); /* MPI Programs end with MPI Finalize; this is a weak synchronization point */
    return 0;
}
