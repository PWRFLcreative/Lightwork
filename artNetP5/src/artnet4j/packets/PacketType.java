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

public enum PacketType {

    ART_POLL(0x2000, ArtPollPacket.class), ART_POLL_REPLY(0x2100,
            ArtPollReplyPacket.class), ART_OUTPUT(0x5000, null), ART_ADDRESS(
            0x6000, null), ART_INPUT(0x7000, null), ART_TOD_REQUEST(0x8000,
            null), ART_TOD_DATA(0x8100, null), ART_TOD_CONTROL(0x8200, null),
    ART_RDM(0x8300, null), ART_RDMSUB(0x8400, null), ART_MEDIA(0x9000, null),
    ART_MEDIA_PATCH(0x9100, null), ART_MEDIA_CONTROL(0x9200, null),
    ART_MEDIA_CONTROL_REPLY(0x9300, null), ART_VIDEO_SETUP(0xa010, null),
    ART_VIDEO_PALETTE(0xa020, null), ART_VIDEO_DATA(0xa040, null),
    ART_MAC_MASTER(0xf000, null), ART_MAC_SLAVE(0xf100, null),
    ART_FIRMWARE_MASTER(0xf200, null), ART_FIRMWARE_REPLY(0xf300, null),
    ART_IP_PROG(0xf800, null), ART_IP_PROG_REPLY(0xf900, null);

    private final int opCode;
    private final Class<? extends ArtNetPacket> packetClass;

    private PacketType(int code, Class<? extends ArtNetPacket> clazz) {
        opCode = code;
        packetClass = clazz;
    }

    public ArtNetPacket createPacket() {
        ArtNetPacket p = null;
        if (packetClass != null) {
            try {
                p = packetClass.newInstance();
            } catch (InstantiationException e) {
                e.printStackTrace();
            } catch (IllegalAccessException e) {
                e.printStackTrace();
            }
        }
        return p;
    }

    /**
     * Returns the opcode for this packet type.
     * 
     * @return the opCode
     */
    public int getOpCode() {
        return opCode;
    }
}