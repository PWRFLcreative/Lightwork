/*
 * This file is part of artnet4j.
 * 
 * Copyright 2009 Karsten Schmidt (PostSpectacular Ltd.)
 * 
 * artnet4j is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * artnet4j is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with artnet4j. If not, see <http://www.gnu.org/licenses/>.
 */

package artnet4j.packets;

import java.net.DatagramPacket;
import java.util.logging.Logger;

public class ArtNetPacketParser {

    public static final Logger logger =
            Logger.getLogger(ArtNetPacketParser.class.getClass().getName());

    public static ArtNetPacket createPacketForOpCode(int opCode, byte[] data) {
        logger.finer("creating packet instance for opcode: 0x"
                + ByteUtils.hex(opCode, 4));
        ArtNetPacket packet = null;
        for (PacketType type : PacketType.values()) {
            if (opCode == type.getOpCode()) {
                packet = type.createPacket();
                if (packet != null) {
                    packet.parse(data);
                    break;
                } else {
                    logger.fine("packet type valid, but not yet supported: "
                            + type);
                }
            }
        }
        return packet;
    }

    private static ArtNetPacket parse(byte[] raw, int offset, int length) {
        ArtNetPacket packet = null;
        ByteUtils data = new ByteUtils(raw);
        if (data.length > 10) {
            if (data.compareBytes(ArtNetPacket.HEADER, 0, 8)) {
                int opCode = data.getInt16LE(8);
                packet = createPacketForOpCode(opCode, raw);
            } else {
                logger.warning("invalid header");
            }
        } else {
            logger.warning("invalid packet length: " + data.length);
        }
        return packet;
    }

    public static ArtNetPacket parse(DatagramPacket receivedPacket) {
        return parse(receivedPacket.getData(), receivedPacket.getOffset(),
                receivedPacket.getLength());
    }
}
