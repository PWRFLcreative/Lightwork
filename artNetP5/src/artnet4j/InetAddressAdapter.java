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

import javax.xml.bind.annotation.adapters.XmlAdapter;

public class InetAddressAdapter extends XmlAdapter<String, InetAddress> {

	@Override
	public String marshal(InetAddress adr) throws Exception {
		return adr.getHostAddress();
	}

	@Override
	public InetAddress unmarshal(String adr) throws Exception {
		return InetAddress.getByName(adr);
	}

}
