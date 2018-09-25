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
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Logger;

import artnet4j.events.ArtNetDiscoveryListener;
import artnet4j.packets.ArtPollPacket;
import artnet4j.packets.ArtPollReplyPacket;

public class ArtNetNodeDiscovery implements Runnable {

	public static final int POLL_INTERVAL = 10000;

	public static final Logger logger = Logger
			.getLogger(ArtNetNodeDiscovery.class.getClass().getName());

	protected final ArtNet artNet;
	protected ConcurrentHashMap<InetAddress, ArtNetNode> discoveredNodes = new ConcurrentHashMap<InetAddress, ArtNetNode>();
	protected List<ArtNetNode> lastDiscovered = new ArrayList<ArtNetNode>();
	protected List<ArtNetDiscoveryListener> listeners = new ArrayList<ArtNetDiscoveryListener>();

	protected boolean isActive = true;

	protected long discoveryInterval;

	private Thread discoveryThread;

	public ArtNetNodeDiscovery(ArtNet artNet) {
		this.artNet = artNet;
		setInterval(POLL_INTERVAL);
	}

	public void addListener(ArtNetDiscoveryListener l) {
		synchronized (listeners) {
			listeners.add(l);
		}
	}

	public void discoverNode(ArtPollReplyPacket reply) {
		InetAddress nodeIP = reply.getIPAddress();
		ArtNetNode node = discoveredNodes.get(nodeIP);
		if (node == null) {
			logger.info("discovered new node: " + nodeIP);
			node = reply.getNodeStyle().createNode();
			node.extractConfig(reply);
			discoveredNodes.put(nodeIP, node);
			for (ArtNetDiscoveryListener l : listeners) {
				l.discoveredNewNode(node);
			}
		} else {
			node.extractConfig(reply);
		}
		lastDiscovered.add(node);
	}

	public void removeListener(ArtNetDiscoveryListener l) {
		synchronized (listeners) {
			listeners.remove(l);
		}
	}

	@Override
	public void run() {
		try {
			while (isActive) {
				lastDiscovered.clear();
				ArtPollPacket poll = new ArtPollPacket();
				artNet.broadcastPacket(poll);
				Thread.sleep(ArtNet.ARTPOLL_REPLY_TIMEOUT);
				if (isActive) {
					synchronized (listeners) {
						for (ArtNetNode node : discoveredNodes.values()) {
							if (!lastDiscovered.contains(node)) {
								discoveredNodes.remove(node.getIPAddress());
								for (ArtNetDiscoveryListener l : listeners) {
									l.discoveredNodeDisconnected(node);
								}
							}
						}
						for (ArtNetDiscoveryListener l : listeners) {
							l.discoveryCompleted(new ArrayList<ArtNetNode>(
									discoveredNodes.values()));
						}
					}
					Thread.sleep(discoveryInterval
							- ArtNet.ARTPOLL_REPLY_TIMEOUT);
				}
			}
		} catch (InterruptedException e) {
			logger.warning("node discovery interrupted");
		}
	}

	public void setInterval(int interval) {
		discoveryInterval = Math.max(interval, ArtNet.ARTPOLL_REPLY_TIMEOUT);
	}

	public void start() throws ArtNetException {
		if (discoveryThread == null) {
			discoveryThread = new Thread(this);
			discoveryThread.start();
		} else {
			throw new ArtNetException("discovery already started.");
		}
	}

	public void stop() {
		isActive = false;
	}
}