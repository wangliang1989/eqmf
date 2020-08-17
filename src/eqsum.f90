program eqsum
use sacio
implicit none
character(len=1024) :: arg
character(len=:) ,allocatable :: file
integer :: i, j, num, flag
real, allocatable, dimension(:) :: data, x
real :: threshold, time, sigma, th, mad, mean
type(sachead) :: head

call get_command_argument(1, arg)
read(arg,*) threshold

call get_command_argument(2, arg)
read(arg,*) num

call get_command_argument(3, arg)
file = trim(arg)
call sacio_readsac(file, head, data, flag)
if (flag /= 0) then
    write(0,*)"can not open file ", file
end if

allocate(x(1 : head%npts))
x = data
deallocate(data)

i = 4
do while (i <= command_argument_count())
    call get_command_argument(i, arg)
    file = trim(arg)
    call sacio_readsac(file, head, data, flag)
    if (flag /= 0) then
        write(0,*)"can not open file", file
    end if
    x = x + data
    deallocate(data)
    deallocate(file)
    i = i + 1
end do

x = x / (i - 3)
mean = sum(x) / head%npts
sigma = sqrt (sum((x - mean) * (x - mean)) / head%npts)
mad = sigma / 1.4826
th = mad * threshold
do j = 1, head%npts
    if (x(j) >= th) then
        time = (j - 1) * head%delta + head%b
        write(*,100) time, x(j), mad, th
    end if
end do
100 format(3I10, F15.2, 3ES25.10)
end program eqsum
