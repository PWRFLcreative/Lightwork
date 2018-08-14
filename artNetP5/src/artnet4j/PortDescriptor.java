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

public class PortDescriptor {

    protected boolean canOutput;
    protected boolean canInput;
    protected PortType type;

    public PortDescriptor(int id) {
        canOutput = (id & 0x80) > 0;
        canInput = (id & 0x40) > 0;
        id &= 0x3f;
        for (PortType t : PortType.values()) {
            if (id == t.getPortID()) {
                type = t;
            }
        }
    }

    /**
     * @return the canInput
     */
    public boolean canInput() {
        return canInput;
    }

    /**
     * @return the canOutput
     */
    public boolean canOutput() {
        return canOutput;
    }

    /**
     * @return the type
     */
    public PortType getType() {
        return type;
    }

    @Override
    public String toString() {
        return "PortDescriptor: " + type + " out: " + canOutput + " in: "
                + canInput;
    }
}
