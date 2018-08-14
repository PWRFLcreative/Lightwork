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

public class ArtPollPacket extends ArtNetPacket {

    private static int ARTPOLL_LENGTH = 14;

    private boolean replyOnce;
    private boolean replyDirect;

    public ArtPollPacket() {
        this(true, true);
    }

    public ArtPollPacket(boolean replyOnce, boolean replyDirect) {
        super(PacketType.ART_POLL);
        setData(new byte[ARTPOLL_LENGTH]);
        setHeader();
        setProtocol();
        setTalkToMe(replyOnce, replyDirect);
    }

    @Override
    public int getLength() {
        return data.getLength();
    }

    @Override
    public boolean parse(byte[] raw) {
        setData(raw, ARTPOLL_LENGTH);
        int talk = data.getInt8(12);
        replyOnce = 0 == (talk & 0x02);
        replyDirect = 1 == (talk & 0x01);
        return true;
    }

    private void setTalkToMe(boolean replyOnce, boolean replyDirect) {
        this.replyOnce = replyOnce;
        this.replyDirect = replyDirect;
        data.setInt8((replyOnce ? 0 : 2) | (replyDirect ? 1 : 0), 12);
    }

    @Override
    public String toString() {
        return type + ": reply once:" + replyOnce + " direct: " + replyDirect;
    }
}
