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

import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.adapters.XmlJavaTypeAdapter;

public class DmxUniverseConfig {

    @XmlAttribute
    public String id;

    @XmlAttribute
    @XmlJavaTypeAdapter(InetAddressAdapter.class)
    public InetAddress ip;

    @XmlAttribute(name = "universe")
    public int universeID;

    @XmlAttribute(name = "numchannels")
    public int numDmxChannels;

    @XmlAttribute(name = "port")
    public int serverPort;

    @XmlAttribute
    public boolean ignoreNumChannels;

    @Override
    public String toString() {
        return "nodeConfig: id=" + id + ", ip=" + ip + ", uid=" + universeID
                + ", nc=" + numDmxChannels;
    }
}