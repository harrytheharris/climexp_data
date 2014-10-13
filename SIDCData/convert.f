        program convert
*
*       convert http://sidc.oma.be/DATA/monthssn.dat
*       into standard sunspot.dat file
*
        implicit none
        integer yr,mn,i
        real xyr,s,ss(12)
*
        open(1,file='monthssn.dat',status='old')
        open(2,file='sunspots.dat',status='new')
*
        write(2,'(a)') '# sunspot [1] monthly mean sunspot number'
        write(2,'(a)') '# from <a href="http://sidc.oma.be/">SIDC</a>'
*
        do yr=1749,2100
            do mn=1,12
                read(1,*,end=800) i,xyr,ss(mn)
                if ( i/100.ne.yr ) then
                    print *,'error in year: ',yr,mn,i
                    stop
                endif
                if ( mod(i,100).ne.mn ) then
                    print *,'error in month ',yr,mn,i
                    stop
                endif
            enddo
            write(2,'(i5,12f7.1)') yr,ss
        enddo
        stop
  800   continue
        if ( mn.ne.1 ) then
            do i=mn,12
                ss(i) = -999.9
            enddo
            write(2,'(i5,12f7.1)') yr,ss
        endif
        stop
        end