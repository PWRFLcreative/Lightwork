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

import java.net.InetAddress;
import java.util.logging.Logger;

import artnet4j.packets.ArtPollReplyPacket;
import artnet4j.packets.ByteUtils;

public class ArtNetNode {

	protected static final Logger logger = Logger.getLogger(ArtNetNode.class
			.getClass().getName());

	protected final NodeStyle nodeStyle;

	private InetAddress ip;

	private int subSwitch;

	private int oemCode;

	private int nodeStatus;
	private NodeReportCode reportCode;

	private String shortName;
	private String longName;

	private int numPorts;
	private PortDescriptor[] ports;
	private byte[] dmxIns;
	private byte[] dmxOuts;

	public ArtNetNode() {
		this(NodeStyle.ST_NODE);
	}

	public ArtNetNode(NodeStyle style) {
		nodeStyle = style;
	}

	public void extractConfig(ArtPollReplyPacket source) {
		setIPAddress(source.getIPAddress());
		subSwitch = source.getSubSwitch();
		oemCode = source.getOEMCode();
		nodeStatus = source.getNodeStatus();
		shortName = source.getShortName();
		longName = source.getLongName();
		ports = source.getPorts();
		numPorts = ports.length;
		reportCode = source.getReportCode();
		dmxIns = source.getDmxIns();
		dmxOuts = source.getDmxOuts();
		logger.info("updated node config");
	}

	/**
	 * @return the dmxIns
	 */
	public byte[] getDmxIns() {
		return dmxIns;
	}

	/**
	 * @return the dmxOuts
	 */
	public byte[] getDmxOuts() {
		return dmxOuts;
	}

	/**
	 * @return the ip
	 */
	public InetAddress getIPAddress() {
		return ip;
	}

	/**
	 * @return the longName
	 */
	public String getLongName() {
		return longName;
	}

	/**
	 * @return the nodeStatus
	 */
	public int getNodeStatus() {
		return nodeStatus;
	}

	/**
	 * @return the nodeStyle
	 */
	public NodeStyle getNodeStyle() {
		return nodeStyle;
	}

	/**
	 * @return the numPorts
	 */
	public int getNumPorts() {
		return numPorts;
	}

	/**
	 * @return the oemCode
	 */
	public int getOemCode() {
		return oemCode;
	}

	/**
	 * @return the ports
	 */
	public PortDescriptor[] getPorts() {
		return ports;
	}

	/**
	 * @return the reportCode
	 */
	public NodeReportCode getReportCode() {
		return reportCode;
	}

	/**
	 * @return the shortName
	 */
	public String getShortName() {
		return shortName;
	}

	public int getSubNet() {
		return subSwitch;
	}

	public String getSubNetAsHex() {
		return ByteUtils.hex(subSwitch, 2);
	}

	public void setIPAddress(InetAddress ip) {
		this.ip = ip;
	}

	@Override
	public String toString() {
		return "node: " + nodeStyle + " " + ip + " " + longName + ", "
				+ numPorts + " ports, subswitch: "
				+ ByteUtils.hex(subSwitch, 2);
	}
}
