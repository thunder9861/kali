# ipv4.py
#
# Version : 1.0
# Date : 20110811
#
# Author : Bernard Czenkusz
# Email  : bernie@skipole.co.uk

#
# ipv4.py - Module to parse IP V4 addresses
# Copyright (c) 2011 Bernard Czenkusz
#
#    ipv4.py is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    ipv4_parse is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with ipv4.py.  If not, see <http://www.gnu.org/licenses/>.
#

"""Check format of an IP4 address and mask.

Provide functions:
parse(address, mask)
address_in_subnet(address, subnet, mask)"""
   

def _mask_list(mask):
    """Converts a mask integer representation of bits, to a list.
    Given the number of mask bits, such as a number like 16
    Returns a list of the subnet mask, such as [255, 255, 0, 0]"""
    if type(mask)!=int: return None
    if mask>32 or mask<1: return None
    mask_list=[0,0,0,0]
    sum_of_bits=(0,128,192,224,240,248,252,254,255)
    if (mask<9):
        mask_list[0]=sum_of_bits[mask]
        return mask_list
    mask_list[0]=255
    if (mask<17):
        mask_list[1]=sum_of_bits[mask-8]
        return mask_list
    mask_list[1]=255
    if (mask<25):
        mask_list[2]=sum_of_bits[mask-16]
        return mask_list
    mask_list[2]=255
    mask_list[3]=sum_of_bits[mask-24]
    return mask_list


def _address_list(address):
    """Test if the address string is ok.
    Given an IP address string with a format such as 192.168.1.2,
    check this is of the correct format and return an address list
    of four digits if it is valid, and None if it is invalid"""
    # Check a string has been passed
    if type(address)!=str: return None
    # check length
    if len(address)>15: return None
    if (len(address)<7): return None
    if address.count('.')!=3: return None
    try:
        address_list = [ int(digit) for digit in address.split('.') ]
    except Exception:
        return None
    if len(address_list)!=4: return None
    for number in address_list:
        if number>255 or number<0: return None
    return address_list


def _network_address(address_list, mask_list):
    """Given an address_list and mask_list return the network address"""
    network_tuple=(address_list[0] & mask_list[0],
                   address_list[1] & mask_list[1],
                   address_list[2] & mask_list[2],
                   address_list[3] & mask_list[3])
    return "%s.%s.%s.%s" % network_tuple


def _broadcast_address(address_list, mask_list):
    """Given an address_list and mask_list return the broadcast address"""
    broadcast_tuple=(address_list[0] | (255 ^ mask_list[0]),
                     address_list[1] | (255 ^ mask_list[1]),
                     address_list[2] | (255 ^ mask_list[2]),
                     address_list[3] | (255 ^ mask_list[3]))
    return "%s.%s.%s.%s" % broadcast_tuple


def parse(address, mask):
    """Checks the address and mask. return (None, None) on error
    otherwise returns (broadcast address, network address)"""
    try:
        mask = int(mask)
    except Exception:
        return None, None
       
    if address == "255.255.255.255": return None, None
    if address == "0.0.0.0" and mask == 32: return None, None

    address_list = _address_list(address)
    if not address_list: return None, None

    mask_list = _mask_list(mask)
    if not mask_list: return None, None

    broadcast_address = _broadcast_address(address_list, mask_list)
    network_address = _network_address(address_list, mask_list)

    return broadcast_address, network_address
    

def address_in_subnet(address, subnet, mask):
    """Checks if the address is within the given subnet and mask
    If it is, return True
    If it is not, or any error in address format, return False"""
    try:
        mask = int(mask)
    except Exception:
        return False

    broadcast_address, network_address = parse(address, mask)
    if not broadcast_address: return False

    broadcast_subnet, network_subnet = parse(subnet, mask)
    if not broadcast_subnet: return False

    # if the mask is 32, then address and subnet are one and the
    # same thing
    if mask == 32:
        return True if address == subnet else False

    # if they both have the same network address and broadcast
    # address, then they are both within the same subnet and
    # it is fair to say address is within subnet
    if network_address != network_subnet:
        return False
    if broadcast_address != broadcast_subnet:
        return False
    return True



