using .MazeGenerator
using Test

function isequal(a::Node,b::Node)
    return a.x==b.x && a.y==b.y && a.walkable == b.walkable && a.pathNode == b.pathNode && a.visited == b.visited
end

## create a few nodes for use later.
n1=Node(1,9)
n2=Node(2,8)
n3=Node(3,7)
n4=Node(4,6)
n5=Node(5,5)
n6=Node(1,9)
n7=Node(7,3)
n8=Node(8,2)
n9=Node(9,1)

grid = Grid(3)
grid.Nodes = [n1,n2,n3,n4,n5,n6,n7,n8,n9]

    @testset "Node Constructor" begin
        @test isa(Node(5,8),Node)
        @test_throws MethodError Node(5.0,8.0)
    end
    @testset "Grid Constructor" begin
        @test isa(Grid(4),Grid)
        @test_throws MethodError Grid([4.0])
    end
    @testset "Node Tests" begin
        @test isa(n1, Node)
        @test !isequal(n3,n5)
        @test isequal(n1,n6)
    end
    @testset "Create Maze" begin
        @test createMaze(9).xSize == 9
        @test createMaze(9).ySize == 9
        @test createMaze(5,9).xSize == 5 && createMaze(5,9).ySize == 9
        @test_throws MethodError createMaze(9.0)
        @test_throws MethodError createMaze("6")
    end
        
    






