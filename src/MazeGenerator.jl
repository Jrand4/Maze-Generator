module MazeGenerator
using Plots,Random
export createMaze, PlotMaze, Node, Grid

#Vector{T}(undef, n)   // I didn't get to this yet but I commented, removed globals, and removed some redundant code

# The Node struct will handle each cell in the grid
mutable struct Node
    x::Int64              # x position   
    y::Int64              # y position
    g::Int64              # distance from start node
    h::Int64              # distance from end node
    walkable::Bool        # Wall = False, Floor = True
    visited::Bool         # To help generate maze when backtracking
    pathNode::Bool        # To help keep track of path solution
    parent::Node          # To link each path solution node in order
    Node(x::Int64,y::Int64)=new(x,y,0,0,false,false,false)
    Node()=new()
end

# This Grid struct will hold all of our Nodes
mutable struct Grid
    xSize::Int64                # width of maze
    ySize::Int64                # height of maze
    Nodes::Array{Node,1}        # each node in maze
    nodePaths::Array{Node,1}    # each solution node in maze
    startNode::Node             # Node start of maze
    targetNode::Node            # Node target of maze
    Grid(xSize::Int64,ySize::Int64)=new(xSize,ySize,Array{Node,1}(undef,0),Array{Node,1}(undef,0))
    Grid(size::Int64)=new(size,size,Array{Node,1}(undef,0),Array{Node,1}(undef,0))
end

# This Function initializes the grid struct, calls generateMaze(backtracking algorithm) and returns the grid
function createMaze(x::Int64,y::Int64)
    #if(mod(x,2) == 0 || mod(y,2) == 0) throw(ArgumentError("X and Y must be odd integers")) end
    grid = Grid(x,y)
    grid.Nodes = initializeGrid(grid)
    grid = generateMaze(grid)
    grid.Nodes = openEntryExit(grid)
    return grid
end

# Overloaded function to only accept one size (square)
function createMaze(s::Int64) # too muc code
    return createMaze(s,s)
end

# This function sets the startNode and targetNode to walkable as when initiallized they are walls
function openEntryExit(g::Grid)
    g.startNode.walkable = true
    g.targetNode.walkable = true
    g.startNode.pathNode = true
    g.targetNode.pathNode = true
    g.Nodes[getNodeIndex(1,2,g)] = g.startNode
    g.Nodes[getNodeIndex(g.xSize,g.ySize-1,g)] = g.targetNode
    return g.Nodes
end

# This function uses A* to find a solution path from g.startNode to g.targetNode
function solveMaze(g::Grid)
    g = setCosts(g)                              # set node costs (g - distance from startNode,h - distance from targetNode)
    local openNodes = Array{Node,1}(undef,0)     # list of nodes to be evaluated
    local closedNodes = Array{Node,1}(undef,0)   # list of evaluated nodes
    push!(openNodes,g.startNode)                 # adding startNode to open
    
    while(length(openNodes) > 0)                 # while there are nodes to be evaluated... Loop
        local selectedNode = openNodes[1]
        for n in openNodes                       # select the node from nodes that need to be evaluated with the lowest f cost (g + h)
            if ((n.g + n.h) < (selectedNode.g + selectedNode.h) || (n.g + n.h) == (selectedNode.g + selectedNode.h) && n.h < selectedNode.h)
                selectedNode = n
            end
        end
        #print(selectedNode)
        push!(closedNodes,selectedNode)              # add selected node to evaluated
        filter!(x -> x != selectedNode, openNodes)   # filter out selected node from open
        if(selectedNode == g.targetNode)             # if we are at target node, then path found. return...
            g = setPath(g)
            return g
            end                                          # else get the nodes neighbours to see where to go next
        local neighbours = getNeighbours(selectedNode,g)
        for n in neighbours
            if(!(n in closedNodes))
                if(!(n in openNodes) || selectedNode.g + 10 < n.g)     # if the node has not been evaluated and ( is not in open or has a better path then when compared before) 
                    n.g = selectedNode.g+10   # update node cost
                    n.parent = selectedNode   # set/update parent
                    if(!(n in openNodes))     # if neighbour not in open, add to open
                        push!(openNodes,n)
                    end
                    g.Nodes[getNodeIndex(n.x,n.y,g)] = n    # update grid Node with modified node
                end
            end
        end
    end
    g = setPath(g) 
    return g
end

# This function sets all target nodes ancestors to pathNode = true then pushes them in order(backwards) into g.nodePaths
function setPath(g::Grid)
    if(isdefined(g,:targetNode))
        n = g.targetNode
        push!(g.nodePaths,n)
        while(isdefined(n,:parent))
            n.pathNode = true
            n = n.parent
            g.Nodes[getNodeIndex(n.x,n.y,g)] = n
            push!(g.nodePaths,n)
        end
    end
    return g
end
# This functon sets the distance costs of each node (gcost, hcost)
function setCosts(g::Grid)
    i = 0
    for n in g.Nodes
        i = i + 1
        n = distances(n,g)
        g.Nodes[i] = n
    end
    return g
end

# This function sets the distance cost of a single node (gcost,hcost)
function distances(n::Node, g::Grid)
    n.g = (abs(n.x - g.startNode.x) + abs(n.y - g.startNode.y))
    n.h = (abs(n.x - g.targetNode.x) + abs(n.y - g.targetNode.y))
    return n
end

# This function returns all 'Valid' nodes that are adjacent to selected node 
function getNeighbours(n::Node,g::Grid)
    local neighbours = Array{Node,1}(undef,0)
    local index = 0
    for i in n.x-1:n.x+1        # left and right of selected node
        for j in n.y-1:n.y+1    # Up and Down of selected node
            if((i != n.x && j == n.y || i == n.x && j != n.y) && i > 1 && j > 1 && i <= g.xSize && j <= g.ySize) # if node not diagonal and not equal to selected node and within map boundries
                index = getNodeIndex(i,j,g)
                #println(index)
                if(g.Nodes[index].walkable == true)
                    #print("\n(",i,",",j,")")
                    push!(neighbours,g.Nodes[index])
                end
            end
        end
    end
    return neighbours
end

# This function initializes all nodes in grid to their position in grid
function initializeGrid(g::Grid)
    for x in 1:g.xSize
        for y in 1:g.ySize
            n = Node(x,y)
            if(y == 1 || x == 1 || x == g.xSize || y == g.ySize) 
                n.visited = true
                n.walkable = false
            end
            push!(g.Nodes,n)
        end
    end
    return g.Nodes
end

# This function takes in 2D coords and returns 1D coord
function getNodeIndex(x::Int64,y::Int64,g::Grid)
    return (x-1) * g.ySize + y # getting an index as a 1D array from 2D
end

# This function checks ahead to see if a path is valid before proceding
function isValidPath(c::Node,d::Int64, g::Grid)
    if(d == 1)
        return (c.x + 2 < g.xSize + 1 && !g.Nodes[getNodeIndex(c.x + 2,c.y,g)].visited && !g.Nodes[getNodeIndex(c.x + 1,c.y,g)].visited) ? true : false
        #print("\nGoing Right")
    elseif (d == 2)
        return (c.y + 2 < g.ySize + 1 && !g.Nodes[getNodeIndex(c.x,c.y + 2,g)].visited && !g.Nodes[getNodeIndex(c.x,c.y + 1,g)].visited) ? true : false
        #print("\nGoing Down")
    elseif(d == 3)
        return (c.x - 2 > 0 && !g.Nodes[getNodeIndex(c.x - 2,c.y,g)].visited && !g.Nodes[getNodeIndex(c.x - 1,c.y,g)].visited) ? true : false
        #print("\nGoing Left")
    elseif (d == 4)
        return (c.y - 2 > 0 && !g.Nodes[getNodeIndex(c.x,c.y - 2,g)].visited && !g.Nodes[getNodeIndex(c.x,c.y - 1,g)].visited) ? true : false
        #print("\nGoing Up")
    end
    return false
end

# This function gets the 1D index from 2D node coords by direction
function getIndex(s::Node,d::Int64,g::Grid)
    local i = 0
    if(d == 1)
        i = getNodeIndex(s.x + 2, s.y,g)
    elseif (d == 2)
        i = getNodeIndex(s.x, s.y + 2,g)
    elseif(d == 3)
        i = getNodeIndex(s.x - 2, s.y,g)
    elseif (d == 4)
        i = getNodeIndex(s.x, s.y - 2,g)
    end
    return i
end

# This function sets the nodes fields to walkable and visited by direction
function setValidPath(s::Node,d::Int64,g::Grid)
    local i = 0
    if(d == 1)
        i = getNodeIndex(s.x + 2, s.y,g)
        g.Nodes[i] = setNodeBools(g.Nodes[i],true)
        i = getNodeIndex(s.x + 1, s.y,g)
        g.Nodes[i] = setNodeBools(g.Nodes[i],true)
    elseif (d == 2)
        i = getNodeIndex(s.x, s.y + 2,g)
        g.Nodes[i] = setNodeBools(g.Nodes[i],true)
        i = getNodeIndex(s.x, s.y + 1,g)
        g.Nodes[i] = setNodeBools(g.Nodes[i],true)
    elseif(d == 3)
        i = getNodeIndex(s.x - 2, s.y,g)
        g.Nodes[i] = setNodeBools(g.Nodes[i],true)
        i = getNodeIndex(s.x - 1, s.y,g)
        g.Nodes[i] = setNodeBools(g.Nodes[i],true)
    elseif (d == 4)
        i = getNodeIndex(s.x, s.y - 2,g)
        g.Nodes[i] = setNodeBools(g.Nodes[i],true)
        i = getNodeIndex(s.x, s.y - 1,g)
        g.Nodes[i] = setNodeBools(g.Nodes[i],true)
    end
    return g.Nodes
end

# This sets a single nodes boolean fields for maze generation
function setNodeBools(n::Node,b::Bool)
    n.visited = b
    n.walkable = b
    return n
end

# This function contains the backtracking algorithm used to generate a maze from a 2D grid of nodes
function generateMaze(g::Grid)
    
    # Declare local variables
    local stack = Array{Node,1}(undef,0)
    local startY = 2
    local index = getNodeIndex(2,startY,g)
    g.startNode = g.Nodes[getNodeIndex(1,2,g)]
    g.targetNode = g.Nodes[getNodeIndex(g.xSize,g.ySize-1,g)]

    local possible_directions = [1,2,3,4]   # 1 : Right 
                                            # 2 : Down
                                            # 3 : Left
                                            # 4 : Up
    # Set up start Node
    g.Nodes[index].visited = true
    g.Nodes[index].walkable = true
    push!(stack,g.Nodes[index])

    # While stack has Nodes
    while(length(stack) > 0)
        
        local directions = shuffle(possible_directions) 
        selected = pop!(stack)
        #print("\nPopped Node: (", selected.x, "," , selected.y, ")")
        while(length(directions) > 0)
            local direction = pop!(directions)
            if(isValidPath(selected,direction,g))
                g.Nodes = setValidPath(selected,direction,g)
                push!(stack,g.Nodes[getIndex(selected,direction,g)])
                selected = g.Nodes[getIndex(selected,direction,g)]
                directions = shuffle(possible_directions)  
            end
        end
    end
    return g
end

# This function plots the maze and solution (if not empty)
function plotMaze(grid::Grid)
    wallsX = []
    wallsY = []
    floorsX = []
    floorsY = []
    pathX = []
    pathY = []
    s = 5
    xs = 7 * grid.xSize
    ys = 7 * grid.ySize
    if(grid.xSize > 100 || grid.ySize > 100)
        s = 2
        xs = 7 * grid.xSize
        ys = 7 * grid.ySize
    elseif(grid.xSize > 75 && grid.xSize <= 100 || grid.ySize > 75 && grid.ySize <= 100)
        s = 3
        xs = 9 * grid.xSize
        ys = 9 * grid.ySize
    elseif(grid.xSize > 50 && grid.xSize <= 75 || grid.ySize > 50 && grid.ySize <= 75)
        s = 4
        xs = 11 * grid.xSize
        ys = 11 * grid.ySize
    elseif(grid.xSize > 25 && grid.xSize <= 50 || grid.ySize > 25 && grid.ySize <= 50)
        s = 5
        xs = 13 * grid.xSize
        ys = 13 * grid.ySize
    elseif(grid.xSize > 10 && grid.xSize <= 25 || grid.ySize > 10 && grid.ySize <= 25)
        s = 6
        xs = 20 * grid.xSize
        ys = 20 * grid.ySize
    else
        s = 7
        xs = 50 * grid.xSize
        ys = 50 * grid.ySize
    end
    for n in grid.Nodes
        if(n.walkable && !n.pathNode)
            push!(floorsX,n.x)
            push!(floorsY,n.y)

        elseif(!n.walkable && !n.pathNode)
            push!(wallsX,n.x)
            push!(wallsY,n.y)
        else
            push!(pathX,n.x)
            push!(pathY,n.y)
        end
    end
    
    p1 = scatter(wallsX,wallsY,size = (xs,ys), marker = (s, :black, :square), xlim=(0,grid.xSize+1), ylim=(0,grid.ySize+1),label=false)
    p2 = scatter!(floorsX,floorsY,size = (xs,ys), marker = (1, :red, stroke(0, 0.2, :black, :dot)), xlim=(0,grid.xSize+1), ylim=(0,grid.ySize+1),label=false)
    p3 = scatter!(pathX,pathY,size = (xs,ys), marker = (s-1, :cyan, :square, stroke(0)),xlim=(0,grid.xSize+1), ylim=(0,grid.ySize+1),label=false)
end

# This function plots the animation of the solved maze
function plotSolution(grid::Grid)
    wallsX = []
    wallsY = []
    floorsX = []
    floorsY = []
    pathX = []
    pathY = []
    s = 5
    xs = 7 * grid.xSize
    ys = 7 * grid.ySize
    if(grid.xSize > 100 || grid.ySize > 100)
        s = 2
        xs = 7 * grid.xSize
        ys = 7 * grid.ySize
    elseif(grid.xSize > 75 && grid.xSize <= 100 || grid.ySize > 75 && grid.ySize <= 100)
        s = 3
        xs = 9 * grid.xSize
        ys = 9 * grid.ySize
    elseif(grid.xSize > 50 && grid.xSize <= 75 || grid.ySize > 50 && grid.ySize <= 75)
        s = 4
        xs = 11 * grid.xSize
        ys = 11 * grid.ySize
    elseif(grid.xSize > 25 && grid.xSize <= 50 || grid.ySize > 25 && grid.ySize <= 50)
        s = 5
        xs = 13 * grid.xSize
        ys = 13 * grid.ySize
    elseif(grid.xSize > 10 && grid.xSize <= 25 || grid.ySize > 10 && grid.ySize <= 25)
        s = 6
        xs = 15 * grid.xSize
        ys = 15 * grid.ySize
    else
        s = 7
        xs = 30 * grid.xSize
        ys = 30 * grid.ySize
    end
    for n in grid.Nodes
        if(n.walkable && !n.pathNode)
            push!(floorsX,n.x)
            push!(floorsY,n.y)

        elseif(!n.walkable && !n.pathNode)
            push!(wallsX,n.x)
            push!(wallsY,n.y)
        end
    end
    for n in grid.nodePaths
        push!(pathX,n.x)
        push!(pathY,n.y)
    end

    anim = Animation()
    p = scatter!(pathX[:], pathY[:], size=(xs,ys), xlim=(0,grid.xSize+1), ylim=(0,grid.ySize+1),label=false)
    for i in 1:1:length(grid.nodePaths)
        p[4] = pathX[i], pathY[i]
    frame(anim)
    end
    gif(anim, "out.gif", fps=10)
    
end
end



