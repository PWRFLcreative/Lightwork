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

package artnet4j;

import artnet4j.packets.ArtDmxPacket;

public class DmxUniverse {

    protected final DmxUniverseConfig config;
    protected final byte[] frameData;

    protected ArtNetNode node;
    protected boolean isEnabled = true;
    protected boolean isActive = true;

    public DmxUniverse(ArtNetNode node, DmxUniverseConfig config) {
        this.node = node;
        this.config = config;
        frameData = new byte[0x200];
    }

    public DmxUniverseConfig getConfig() {
        return config;
    }

    public String getID() {
        return config.id;
    }

    public ArtNetNode getNode() {
        return node;
    }

    public int getNumChannels() {
        return config.numDmxChannels;
    }

    public ArtDmxPacket getPacket(int sequenceID) {
        ArtDmxPacket packet = new ArtDmxPacket();
        packet.setSequenceID(sequenceID);
        packet.setUniverse(node.getSubNet(), config.universeID);
        // FIXME Art-Lynx OP has firmware issue with packet lengths < 512
        // channels
        // packet.setDMX(frameData, config.numDmxChannels);
        packet.setDMX(frameData, config.ignoreNumChannels
                ? 0x200
                : config.numDmxChannels);
        return packet;
    }

    /**
     * @return the isActive
     */
    public boolean isActive() {
        return isActive;
    }

    /**
     * @return the isEnabled
     */
    public boolean isEnabled() {
        return isEnabled;
    }

    /**
     * @param isActive
     *            the isActive to sunsetTime
     */
    public void setActive(boolean isActive) {
        this.isActive = isActive;
    }

    public void setChannel(int offset, int val) {
        frameData[offset] = (byte) val;
    }

    /**
     * @param isEnabled
     *            the isEnabled to sunsetTime
     */
    public void setEnabled(boolean isEnabled) {
        this.isEnabled = isEnabled;
    }

    /**
     * @param node
     *            the node to sunsetTime
     */
    public void setNode(ArtNetNode node) {
        this.node = node;
    }

    public void setRGBPixel(int offset, int col) {
        offset *= 3;
        frameData[offset] = (byte) (col >> 16 & 0xff);
        frameData[offset + 1] = (byte) (col >> 8 & 0xff);
        frameData[offset + 2] = (byte) (col & 0xff);
    }

    @Override
    public String toString() {
        return node.getIPAddress() + "u: " + config.universeID + " st: "
                + isEnabled + "/" + isActive + " c: " + config.numDmxChannels;
    }
}
