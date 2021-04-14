program eqsum
use sacio
implicit none
character(len=1024) :: arg
character(len=:) ,allocatable :: file
integer :: i, j, num, flag
real, allocatable, dimension(:) :: data, x, nums
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

allocate(nums(1 : head%npts))
nums = num
allocate(x(1 : head%npts))
x = data
do j = 1, head%npts
    if (data(j) == 0) then
        nums(j) = nums(j) - 1
    end if
    if (nums(j) == 0) then
        nums(j) = 1
    end if
end do
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
    do j = 1, head%npts
        if (data(j) == 0) then
            nums(j) = nums(j) - 1
        end if
        if (nums(j) == 0) then
            nums(j) = 1
        end if
    end do
    deallocate(data)
    deallocate(file)
    i = i + 1
end do

x = x / nums
mean = sum(x) / head%npts
sigma = sqrt (sum((x - mean) * (x - mean)) / head%npts)
mad = sigma / 1.4826
th = mad * threshold
do j = 1, head%npts
    if (x(j) >= th) then
        time = (j - 1) * head%delta + head%b
        write(*,*) time, x(j), mad, th
    end if
end do
100 format(3I10, F15.2, 3ES25.10)
end program eqsum
