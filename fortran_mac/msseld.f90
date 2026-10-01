!     Last change:  MR    9 Jun 2000   11:09 am
        program mssel

        use discrete
  !      use selovlp
        use selparameters
        use seltools
        use selroutines

        implicit none

        do i=1,10
          print *," "
        end do
        call intro(1)
        do i=1,3
          print *," "
        end do

1000    print *," discrete generations number of selection stages?  1/2/3, "
	print *," or overlapping generations?  o "
        print *, " "
        read *,stages

        if (stages.eq."1") then
         ! print *,"  wrong input"
        !  goto 1000
          call sel1s
        else if (stages.eq."2") then
      !    print *,"  wrong input"
     !     goto 1000
          call sel2s
        else if (stages.eq."3") then
         ! print *,"  wrong input"
        !  goto 1000
          call sel3s
        else if (stages.eq."o") then
          print *,"  wrong input"
          goto 1000
     !     call ovlp
        else
          print *,"  wrong input"
          goto 1000
        end if

        end program mssel
