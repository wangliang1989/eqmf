program eqcor
use sacio
use module_eqcor
implicit none
character(len=1024) :: arg
character(len=:) ,allocatable :: file, out
integer :: i, flag, npts
real,allocatable,dimension(:) :: x, y, norm, result
real :: b, e
type(sachead) :: headx, heady, head

call get_command_argument(1, arg)
file = trim(arg)
call sacio_readsac(file, headx, x, flag)
deallocate(file)

call get_command_argument(2, arg)
file = trim(arg)
call sacio_readsac(file, heady, y, flag)
deallocate(file)

call get_command_argument(3, arg)
out = trim(arg)

if (headx%delta /= heady%delta) then
    flag = 1
    write(*,*) "sacio_Fortran: delta is not equal in -X file and -Y file"
end if
if (headx%npts < heady%npts) then
    flag = 1
    write(*,*) "sacio_Fortran: npts in -X file is smaller than -Y file"
end if

if (flag == 0) then
    npts = size(x)-size(y)+1
    call sacio_newhead(head, headx%delta, npts, headx%b - heady%e + (heady%npts - 1) * headx%delta)
    head%stlo = headx%stlo
    head%stla = headx%stla
    head%evlo = heady%evlo
    head%evla = heady%evla
    head%evdp = heady%evdp
    call sub_norm(norm, x, size(y), npts)
    call sub_cor(x, y, norm, result, flag)
    head%depmax = maxval(result)
    call sacio_writesac(out, head, result, flag)
end if

end program eqcor
