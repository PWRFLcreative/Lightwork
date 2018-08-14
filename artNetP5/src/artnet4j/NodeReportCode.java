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

public enum NodeReportCode {

    RcDebug("#0000", "Booted in debug mode"),
    RcPowerOk("#0001", "Power On Tests successful"),
    RcPowerFail("#0002", "Hardware tests failed at Power On"),
    RcSocketWr1(
            "#0003",
            "Last UDP from Node failed due to truncated length. Most likely caused by a collision."),
    RcParseFail("#0004",
            "Unable to identify last UDP transmission. Check OpCode and packet length."),
    RcUdpFail("#0005", "Unable to open Udp Socket in last transmission attempt"),
    RcShNameOk("#0006",
            "Confirms that Short Name programming via ArtAddress, was successful."),
    RcLoNameOk("#0007",
            "Confirms that Long Name programming via ArtAddress, was successful."),
    RcDmxError("#0008", "DMX512 receive errors detected."), RcDmxUdpFull(
            "#0009", "Ran out of internal DMX transmit buffers."), RcDmxRxFull(
            "#000a", "Ran out of internal DMX Rx buffers."), RcSwitchErr(
            "#000b", "Rx Universe switches conflict."), RcConfigErr("#000c",
            "Product configuration does not match firmware."), RcDmxShort(
            "#000d", "DMX output short detected. See GoodOutput field."),
    RcFirmwareFail("#000e", "Last attempt to upload new firmware failed."),
    RcUserFail("#000f",
            "User changed switch settings when address locked by remote.");

    public static NodeReportCode getForID(String id) {
        NodeReportCode code = null;
        for (NodeReportCode c : values()) {
            if (c.id.equalsIgnoreCase(id)) {
                code = c;
                break;
            }
        }
        return code;
    }

    private final String id;
    private final String description;

    private NodeReportCode(String id, String desc) {
        this.id = id;
        this.description = desc;
    }

    /**
     * @return the description
     */
    public String getDescription() {
        return description;
    }

    /**
     * @return the id
     */
    public String getID() {
        return id;
    }
}