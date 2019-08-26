not_implemented_for(x) = error("Not implemented for $(x). You might want to put:  `using Makie` into your code!")

#TODO only have one?
const Theme = Attributes

Theme(x::AbstractPlot) = attributes(x)

default_theme(scene, T) = Attributes()

function default_theme(scene)
    light = Vec3f0[Vec3f0(1.0,1.0,1.0), Vec3f0(0.1,0.1,0.1), Vec3f0(0.9,0.9,0.9), Vec3f0(20,20,20)]
    Theme(
        color = theme(scene, :color),
        visible = theme(scene, :visible),
        linewidth = 1,
        light = light,
        transformation = automatic,
        model = automatic,
        alpha = 1.0,
        transparency = false,
        overdraw = false,
    )
end

#this defines which attributes in a theme should be removed if another attribute is defined by the user,
#to avoid conflicts later through the pipeline

mutual_exclusive_attributes(::Type{<:AbstractPlot}) = Dict()


"""
    image(x, y, image)
    image(image)

Plots an image on range `x, y` (defaults to dimensions).

## Theme
$(ATTRIBUTES)
"""
@recipe(Image, x, y, image) do scene
    Theme(;
        default_theme(scene)...,
        colormap = [RGBAf0(0,0,0,1), RGBAf0(1,1,1,1)],
        colorrange = automatic,
        fxaa = false,
    )
end


# could be implemented via image, but might be optimized specifically by the backend
"""
    heatmap(x, y, values)
    heatmap(values)

Plots a heatmap as an image on `x, y` (defaults to interpretation as dimensions).

## Theme
$(ATTRIBUTES)
"""
@recipe(Heatmap, x, y, values) do scene
    Theme(;
        default_theme(scene)...,
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        linewidth = 0.0,
        levels = 1,
        fxaa = true,
        interpolate = false
    )
end

"""
    volume(volume_data)

Plots a volume. Available algorithms are:
* `:iso` => IsoValue
* `:absorption` => Absorption
* `:mip` => MaximumIntensityProjection
* `:absorptionrgba` => AbsorptionRGBA
* `:indexedabsorption` => IndexedAbsorptionRGBA

## Theme
$(ATTRIBUTES)
"""
@recipe(Volume, x, y, z, volume) do scene
    Theme(;
        default_theme(scene)...,
        fxaa = true,
        algorithm = :iso,
        absorption = 1f0,
        isovalue = 0.5f0,
        isorange = 0.05f0,
        color = nothing,
        colormap = theme(scene, :colormap),
        colorrange = (0, 1),
    )
end


"""
    surface(x, y, z)

Plots a surface, where `(x, y)`  define a grid whose heights are the entries in `z`.

## Theme
$(ATTRIBUTES)
"""
@recipe(Surface, x, y, z) do scene
    Theme(;
        default_theme(scene)...,
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        shading = true,
        fxaa = true,
    )
end

"""
    lines(positions)
    lines(x, y)
    lines(x, y, z)

Creates a connected line plot for each element in `(x, y, z)`, `(x, y)` or `positions`.

## Theme
$(ATTRIBUTES)
"""
@recipe(Lines, x, y, z) do scene
    Theme(;
        default_theme(scene)...,
        linewidth = 1.0,
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        linestyle = theme(scene, :linestyle),
        fxaa = false
    )
end

"""
    linesegments(positions)
    linesegments(x, y)
    linesegments(x, y, z)

Plots a line for each pair of points in `(x, y, z)`, `(x, y)`, or `positions`.

## Theme
$(ATTRIBUTES)
"""
@recipe(LineSegments, positions) do scene
    default_theme(scene, Lines)
end

# alternatively, mesh3d? Or having only mesh instead of poly + mesh and figure out 2d/3d via dispatch
"""
    mesh(x, y, z)
    mesh(mesh_object)
    mesh(x, y, z, faces)
    mesh(xyz, faces)

Plots a 3D mesh.

## Theme
$(ATTRIBUTES)
"""
@recipe(Mesh, mesh) do scene
    Theme(;
        default_theme(scene)...,
        fxaa = true,
        interpolate = false,
        shading = true,
        colormap = theme(scene, :colormap),
        colorrange = automatic,
    )
end

"""
    scatter(positions)
    scatter(x, y)
    scatter(x, y, z)

Plots a marker for each element in `(x, y, z)`, `(x, y)`, or `positions`.

## Theme
$(ATTRIBUTES)
"""
@recipe(Scatter, x, y, z) do scene
    Theme(;
        default_theme(scene)...,
        marker = theme(scene, :marker),
        markersize = theme(scene, :markersize),
        strokecolor = RGBA(0, 0, 0, 0),
        strokewidth = 0.0,
        glowcolor = RGBA(0, 0, 0, 0),
        glowwidth = 0.0,
        rotations = Billboard(),
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        marker_offset = automatic,
        fxaa = false,
        transform_marker = false, # Applies the plots transformation to marker
        uv_offset_width = Vec4f0(0),
        distancefield = nothing,
    )
end

"""
    meshscatter(positions)
    meshscatter(x, y)
    meshscatter(x, y, z)

Plots a mesh for each element in `(x, y, z)`, `(x, y)`, or `positions` (similar to `scatter`).
`markersize` is a scaling applied to the primitive passed as `marker`.

## Theme
$(ATTRIBUTES)
"""
@recipe(MeshScatter, x, y, z) do scene
    Theme(;
        default_theme(scene)...,
        marker = Sphere(Point3f0(0), 1f0),
        markersize = theme(scene, :markersize),
        rotations = Quaternionf0(0, 0, 0, 1),
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        fxaa = true,
        shading = true
    )
end

"""
    text(string)

Plots a text.

## Theme
$(ATTRIBUTES)
"""
@recipe(Text, text) do scene
    Theme(;
        default_theme(scene)...,
        font = theme(scene, :font),
        strokecolor = (:black, 0.0),
        strokewidth = 0,
        align = (:left, :bottom),
        rotation = 0.0,
        textsize = 20,
        position = Point2f0(0),
    )
end

const atomic_function_symbols = (
    :text, :meshscatter, :scatter, :mesh, :linesegments,
    :lines, :surface, :volume, :heatmap, :image
)

const atomic_functions = getfield.(Ref(AbstractPlotting), atomic_function_symbols)

function color_and_colormap!(plot, intensity = plot[:color])
    if isa(intensity[], AbstractArray{<: Number})
        haskey(plot, :colormap) || error("Plot $T needs to have a colormap to allow the attribute color to be an array of numbers")
        replace_automatic!(plot, :colorrange) do
            lift(extrema_nan, intensity)
        end
        true
    else
        delete!(plot, :colorrange)
        false
    end
end

"""
    `calculated_attributes!(plot::AbstractPlot)`

Fill in values that can only be calculated when we have all other attributes filled
"""
calculated_attributes!(plot::T) where T = calculated_attributes!(T, plot)

"""
    `calculated_attributes!(trait::Type{<: AbstractPlot}, plot)`
trait version of calculated_attributes
"""
calculated_attributes!(trait, plot) = nothing
#
# function calculated_attributes!(::Type{<: Mesh}, plot)
#     need_cmap = color_and_colormap!(plot)
#     need_cmap || delete!(plot, :colormap)
#     return
# end
#
# function calculated_attributes!(::Type{<: Union{Heatmap, Image}}, plot)
#     plot[:color] = plot[3]
#     color_and_colormap!(plot)
# end
# function calculated_attributes!(::Type{<: Surface}, plot)
#     colors = plot[3]
#     if haskey(plot, :color)
#         color = plot[:color][]
#         if isa(color, AbstractMatrix{<: Number}) && !(color === to_value(colors))
#             colors = plot[:color]
#         end
#     end
#     color_and_colormap!(plot, colors)
# end
# function calculated_attributes!(::Type{<: MeshScatter}, plot)
#     color_and_colormap!(plot)
# end
#
#
# function calculated_attributes!(::Type{<: Scatter}, plot)
#     # calculate base case
#     color_and_colormap!(plot)
#     replace_automatic!(plot, :marker_offset) do
#         # default to middle
#         lift(x-> to_2d_scale(x .* (-0.5f0)), plot[:markersize])
#     end
# end
#
# function calculated_attributes!(::Type{<: Union{Lines, LineSegments}}, plot)
#     color_and_colormap!(plot)
#     pos = plot[1][]
#     # extend one color per linesegment to be one (the same) color per vertex
#     # taken from @edljk  in PR #77
#     if haskey(plot, :color) && isa(plot[:color][], AbstractVector) && iseven(length(pos)) && (length(pos) ÷ 2) == length(plot[:color][])
#         plot[:color] = lift(plot[:color]) do cols
#             map(i-> cols[(i + 1) ÷ 2], 1:(length(cols) * 2))
#         end
#     end
# end

"""
    used_attributes(args...) = ()

function used to indicate what keyword args one wants to get passed in `convert_arguments`.
Usage:
```example
    struct MyType end
    used_attributes(::MyType) = (:attribute,)
    function convert_arguments(x::MyType; attribute = 1)
        ...
    end
    # attribute will get passed to convert_arguments
    # without keyword_verload, this wouldn't happen
    plot(MyType, attribute = 2)
    #You can also use the convenience macro, to overload convert_arguments in one step:
    @keywords convert_arguments(x::MyType; attribute = 1)
        ...
    end
```
"""
used_attributes(PlotType, args...) = ()


function seperate_tuple(args::Node{<: NTuple{N, Any}}) where N
    ntuple(N) do i
        lift(args) do x
            if i <= length(x)
                x[i]
            else
                error("You changed the number of arguments. This isn't allowed!")
            end
        end
    end
end


"""
    `plot_type(plot_args...)`

The default plot type for any argument is `lines`.
Any custom argument combination that has only one meaningful way to be plotted should overload this.
e.g.:
```example
    # make plot(rand(5, 5, 5)) plot as a volume
    plottype(x::Array{<: AbstractFlot, 3}) = Volume
```
"""
plottype(::RealVector, ::RealVector) = lines!
plottype(::RealVector) = lines!
plottype(::AbstractMatrix{<: Real}) = heatmap!

plot(args...; kw...) = plot!(Scene(), args...; kw...)
plot!(args...; kw...) = plot!(current_scene(), args...; kw...)
plot(scene::Scene, args...; kw...) = plot!(Scene(scene), args...; kw...)
plot!(scene::Scene, args...; kw...) = plottype(args...)(scene, args...; kw...)

plot(scene::Scene, attributes::Attributes, args...; kw...) = plot!(Scene(scene), merge!(Attributes(kw), attributes), args...)
plot(attributes::Attributes, args...; kw...) = plot!(Scene(), merge!(Attributes(kw), attributes), args...)
plot!(attributes::Attributes, args...; kw...) = plot!(current_scene(), merge!(Attributes(kw), attributes), args...)

function plot!(scene::Scene, attributes::Attributes, args...; kw...)
    plottype(args...)(scene, merge!(Attributes(kw), attributes), args...)
end
# Overload remaining functions
# eval(default_plot_signatures(:plot, :plot!))


"""
Main plotting signatures that plot/plot! route to if no Plot Type is given
"""
function plot!(scene::Scene, plot::Plot)
    push!(scene.plots, plot)
    return scene
end


function show_attributes(attributes)
    for (k, v) in attributes
        println("    ", k, ": ", v[] == nothing ? "nothing" : v[])
    end
end

function plot!(scene::SceneLike, attributes::Attributes, input::NTuple{N, Node}, args::Node) where {N, PlotType <: AbstractPlot}
    push!(scene, plot_object)

    if !scene.raw[] || scene[:camera][] !== automatic
        # if no camera controls yet, setup camera
        setup_camera!(scene)
    end
    if !scene.raw[]
        add_axis!(scene, scene.attributes)
    end
    # ! ∘ isaxis --> (x)-> !isaxis(x)
    # move axis to front, so that scene[end] gives back the last plot and not the axis!
    if !isempty(scene.plots) && isaxis(last(scene.plots))
        axis = pop!(scene.plots)
        pushfirst!(scene.plots, axis)
    end
    scene
end

function plot!(scene::Plot, ::Type{PlotType}, attributes::Attributes, input::NTuple{N,Node}, args::Node) where {N, PlotType <: AbstractPlot}
    # create "empty" plot type - empty meaning containing no plots, just attributes + arguments
    plot_object = PlotType(scene, attributes, input, args)
    # call user defined recipe overload to fill the plot type
    plot!(plot_object)
    push!(scene.plots, plot_object)
    scene
end

function apply_camera!(scene::Scene, cam_func)
    if cam_func in (cam2d!, cam3d!, campixel!, cam3d_cad!)
        cam_func(scene)
    else
        error("Unrecognized `camera` attribute type: $(typeof(cam_func)). Use automatic, cam2d! or cam3d!, campixel!, cam3d_cad!")
    end
end


function setup_camera!(scene::Scene)
    theme_cam = scene[:camera][]
    if theme_cam == automatic
        cam = cameracontrols(scene)
        # only automatically add camera when cameracontrols are empty (not set)
        if cam == EmptyCamera()
            if is2d(scene)
                cam2d!(scene)
            else
                cam3d!(scene)
            end
        end
    else
        apply_camera!(scene, theme_cam)
    end
    scene
end

function find_in_plots(scene::Scene, key::Symbol)
    # TODO findfirst is a bit flaky... maybe merge multiple ranges + tick labels?!
    idx = findfirst(scene.plots) do plot
        !isaxis(plot) && haskey(plot, key) && plot[key][] !== automatic
    end
    if idx !== nothing
        scene.plots[idx][key]
    else
        automatic
    end
end

function add_axis!(scene::Scene, attributes = Attributes())
    show_axis = scene.show_axis[]
    show_axis isa Bool || error("show_axis needs to be a bool")
    axistype = if scene.axis_type[] == automatic
        is2d(scene) ? axis2d! : axis3d!
    elseif scene.axis_type[] in (axis2d!, axis3d!)
        scene.axis_type[]
    else
        error("Unrecogniced `axis_type` attribute type: $(typeof(scene[:axis_type][])). Use automatic, axis2d! or axis3d!")
    end

    if show_axis && scene[Axis] === nothing
        axis_attributes = Attributes()
        for key in (:axis, :axis2d, :axis3d)
            if haskey(scene, key) && !isempty(scene[key])
                axis_attributes = scene[key]
                break
            end
        end
        ranges = get(attributes, :tickranges) do
            find_in_plots(scene, :tickranges)
        end
        labels = get(attributes, :ticklabels) do
            find_in_plots(scene, :ticklabels)
        end
        lims = lift(scene.limits, scene.data_limits) do sl, dl
            sl === automatic && return dl
            return sl
        end
        axistype(
            scene, axis_attributes, lims,
            ticks = (ranges = ranges, labels = labels)
        )
    end
    scene
end

function add_labels!(scene::Scene)
    if plot_attributes.show_legend[] && haskey(p.attributes, :colormap)
        legend_attributes = plot_attributes[:legend][]
        colorlegend(scene, p.attributes[:colormap], p.attributes[:colorrange], legend_attributes)
    end
    scene
end
