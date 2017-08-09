"""Simple high-performance Open Pixel Control client."""
#
# Copyright (c) 2013 Micah Elizabeth Scott
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
   
import json
import numpy
import os
import socket
import struct
import time


class FastOPC(object):
    """High-performance Open Pixel Control client, using Numeric Python.
       By default, assumes the OPC server is running on localhost. This may be overridden
       with the OPC_SERVER environment variable, or the 'server' keyword argument.
       """

    def __init__(self, server=None):
        self.server = server or os.getenv('OPC_SERVER') or '127.0.0.1:7890'
        self.host, port = self.server.split(':')
        self.port = int(port)
        self.socket = None


    def send(self, packet):
        """Send a low-level packet to the OPC server, connecting if necessary
           and handling disconnects. Returns True on success.
           """

        if self.socket is None:
            try:
                self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                self.socket.connect((self.host, self.port))
                self.socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, True)
            except socket.error:
                self.socket = None

        if self.socket is not None:        
            try:
                self.socket.send(packet)
                return True
            except socket.error:
                self.socket = None

        # Limit CPU usage when polling for a server
        time.sleep(0.1)

        return False

    def putPixels(self, channel, *sources):
        """Send a list of 8-bit colors to the indicated channel. (OPC command 0x00).
           This command accepts a list of pixel sources, which are concatenated and sent.
           Pixel sources may be:

            - Strings or buffer objects containing pre-formatted 8-bit RGB pixel data
            - NumPy arrays or sequences containing 8-bit RGB pixel data.
              If values are out of range, the array is modified.
           """

        parts = []
        bytes = 0

        for source in sources:
            if isinstance(source, buffer):
                source = str(source)
            elif not isinstance(source, str):
                if not isinstance(source, numpy.ndarray):
                    source = numpy.array(source)
                numpy.clip(source, 0, 255, source)
                source = source.astype('B').tostring()

            bytes += len(source)
            parts.append(source)

        parts.insert(0, struct.pack('>BBH', channel, 0, bytes))
        self.send(''.join(parts))

    def sysEx(self, systemId, commandId, msg):
        self.send(struct.pack(">BBHHH", 0, 0xFF, len(msg) + 4, systemId, commandId) + msg)

    def setGlobalColorCorrection(self, gamma, r, g, b):
        self.sysEx(1, 1, json.dumps({'gamma': gamma, 'whitepoint':[r,g,b]}))
