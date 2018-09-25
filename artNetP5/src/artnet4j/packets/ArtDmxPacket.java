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

public class ArtDmxPacket extends ArtNetPacket {

    private int numChannels;
    private int sequenceID;
    private int subnetID;
    private int universeID;

    public ArtDmxPacket() {
        super(PacketType.ART_OUTPUT);
        setData(new byte[530]);
        setHeader();
        setProtocol();
        data.setInt8(0x02, 13);
    }

    /**
     * @return the actual packet size used. If an odd number DMX channels is
     *         used, the packet size is made even automatically.
     * 
     * @see artnet4j.packets.ArtNetPacket#getLength()
     */
    @Override
    public int getLength() {
        return 18 + (1 == numChannels % 2 ? numChannels + 1 : numChannels);
    }

    /**
     * @return the number of DMX channels
     */
    public int getNumChannels() {
        return numChannels;
    }

    /**
     * @return the sequenceID
     */
    public int getSequenceID() {
        return sequenceID;
    }

    /**
     * @return the subnetID
     */
    public int getSubnetID() {
        return subnetID;
    }

    /**
     * @return the universeID
     */
    public int getUniverseID() {
        return universeID;
    }

    @Override
    public boolean parse(byte[] raw) {
        return false;
    }

    public void setDMX(byte[] dmxData, int numChannels) {
        logger.finer("setting DMX data for: " + numChannels + " channels");
        this.numChannels = numChannels;
        data.setByteChunk(dmxData, 18, numChannels);
        data.setInt16((1 == numChannels % 2 ? numChannels + 1 : numChannels),
                16);
    }

    /**
     * @param numChannels
     *            the number of DMX channels to set
     */
    public void setNumChannels(int numChannels) {
        this.numChannels = numChannels > 512 ? 512 : numChannels;
    }

    public void setSequenceID(int id) {
        sequenceID = id % 0xff;
        data.setInt8(id, 12);
    }

    /**
     * @param subnetID
     *            the subnetID to set
     */
    public void setSubnetID(int subnetID) {
        this.subnetID = subnetID & 0x0f;
    }

    public void setUniverse(int subnetID, int universeID) {
        this.subnetID = subnetID & 0x0f;
        this.universeID = universeID & 0x0f;
        data.setInt16LE(subnetID << 4 | universeID, 14);
        logger.finer("universe ID set to: subnet: "
                + ByteUtils.hex(subnetID, 2) + "/"
                + ByteUtils.hex(universeID, 2));
    }

    /**
     * @param universeID
     *            the universeID to set
     */
    public void setUniverseID(int universeID) {
        this.universeID = universeID & 0x0f;
    }
}
