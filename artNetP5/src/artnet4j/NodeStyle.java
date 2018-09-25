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

public enum NodeStyle {
    ST_NODE(0, ArtNetNode.class), ST_SERVER(1, ArtNetServer.class), ST_MEDIA(2,
            ArtNetNode.class), ST_ROUTER(3, ArtNetNode.class), ST_BACKUP(4,
            ArtNetNode.class), ST_CONFIG(5, ArtNetNode.class);

    private int id;
    private Class<? extends ArtNetNode> nodeClass;

    private NodeStyle(int id, Class<? extends ArtNetNode> nodeClass) {
        this.id = id;
        this.nodeClass = nodeClass;
    }

    public ArtNetNode createNode() {
        ArtNetNode node = null;
        try {
            node = nodeClass.newInstance();
        } catch (InstantiationException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        }
        return node;
    }

    public int getStyleID() {
        return id;
    }
}
