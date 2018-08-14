/**
 * 
 */
package artnetP5;

import java.net.InetAddress;
import java.net.SocketException;
import java.util.ArrayList;
import java.util.List;

import artnet4j.ArtNet;
import artnet4j.ArtNetException;
import artnet4j.ArtNetNode;
import artnet4j.events.ArtNetDiscoveryListener;
import artnet4j.packets.ArtDmxPacket;

/**
 * @class ArtnetP5
 * @note  
 * 
 * @author sadmb
 * @date 2013/06/14
 */
public class ArtnetP5 implements ArtNetDiscoveryListener{
	public static ArtNet ARTNET;
	public ArrayList<ArtNetNode> nodes;
	InetAddress interfaceIP;
	private int sequenceID;
	
	
	public ArtnetP5(){
	}
	
	public void setup(){
		if(ARTNET == null){
			ARTNET = new ArtNet();
			try{
				ARTNET.start();
				ARTNET.getNodeDiscovery().addListener(this);
				ARTNET.startNodeDiscovery();
			}catch(SocketException e){
				e.printStackTrace();
			}catch(ArtNetException e){
				e.printStackTrace();
			}
		}
	}
	
	public void send(byte[] buffer, String interfaceIP){
		ArtNetNode node = getNode(interfaceIP);
		if(node != null){
			ArtDmxPacket dmx = new ArtDmxPacket();
			dmx.setUniverse(node.getSubNet(), node.getDmxOuts()[0]);
			dmx.setSequenceID(sequenceID % 255);
			dmx.setDMX(buffer, buffer.length);
			ARTNET.unicastPacket(dmx, interfaceIP);
			sequenceID++;
		}else{
			System.err.println("node not found: " + interfaceIP);
		}
	}
	
	public void send(int[] pixels, String interfaceIP){
		send(convertPixels(pixels), interfaceIP);
	}
	
	public void broadcast(byte[] buffer){
		if(nodes.size() > 0){
			ArtDmxPacket dmx = new ArtDmxPacket();
			dmx.setUniverse(0, 0);
			dmx.setSequenceID(sequenceID % 255);
			dmx.setDMX(buffer, buffer.length);
			ARTNET.broadcastPacket(dmx);
			sequenceID++;
		}
	}
	public void broadcast(int[] pixels){
		broadcast(convertPixels(pixels));
	}
	
	private byte[] convertPixels(int[] pixels){
		byte[] buffer = new byte[pixels.length * 3];
		for(int i = 0; i < pixels.length; i++){
			buffer[3 * i + 0] = (byte)(pixels[i] & 0xFF000000 >> 24);
			buffer[3 * i + 1] = (byte)(pixels[i] & 0x00FF0000 >> 16);
			buffer[3 * i + 2] = (byte)(pixels[i] & 0x0000FF00 >> 8);
		}
		return buffer;
	}
	
	public ArrayList<ArtNetNode> getNodes(){
		return nodes;
	}
	
	public ArtNetNode getNode(String interfaceIP){
		for(ArtNetNode n : nodes){
			if(n.getIPAddress().getHostAddress().equals(interfaceIP)){
				return n;
			}
		}
		return null;
	}
	
	@Override
	public void discoveredNewNode(ArtNetNode node) {
		nodes.add(node);
		System.out.println("found node:" + node);
	}

	@Override
	public void discoveredNodeDisconnected(ArtNetNode node) {
		System.out.println("node disconnected: " + node);
		for(int i = nodes.size() - 1; i >= 0; i--){
			if(nodes.get(i) == node){
				nodes.remove(i);
			}
		}
	}

	@Override
	public void discoveryCompleted(List<ArtNetNode> nodes) {
		System.out.println(nodes.size() + " nodes found:");
		for (ArtNetNode n : nodes) {
			System.out.println("---------- " + n.getIPAddress().getHostAddress() + " ----------");
			System.out.println("Short Name: " + n.getShortName());
			System.out.println("Long Name: " + n.getLongName());
			System.out.println("Node Status: " + n.getNodeStatus());
			System.out.println("SubnetID: " + n.getSubNet());
			System.out.println("UniverseID: " + n.getDmxOuts()[0]);
			System.out.println("NumPorts: " + n.getNumPorts());
			System.out.println("--------------------------------");
		}
	}

	@Override
	public void discoveryFailed(Throwable t) {
		System.out.println("discovery failed");
	}
}	
