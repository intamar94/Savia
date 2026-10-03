# MUNDO VIVO — World Design System v1

Status: design-only. No gameplay implementation.

## 1. North star
Mundo Vivo must read as an ecosystem before it reads as a level. Every visible element belongs to a causal chain: geology -> water -> soil -> vegetation -> fungi/microorganisms -> insects/fauna -> disturbance -> regeneration.

Reference target: contemporary premium open-world density, coherence, legibility, environmental variation and finish. External games are quality references only; no protected assets, maps, distinctive layouts, names, textures, audio, models or other expression are to be copied.

## 2. World grammar
The world is assembled from ecological cells rather than decorative biomes. Each cell stores:
- substrate/geology
- elevation, slope, aspect and exposure
- water availability and drainage
- soil horizon and organic matter
- canopy/understory/ground-cover structure
- root and mycorrhizal layers
- decomposition state
- characteristic fauna/invertebrates
- disturbance history
- season/time/weather response
- human trace where appropriate

Transitions must be gradients. Hard biome borders are forbidden unless physically justified (cliff, river, fire scar, road, cultivation edge, etc.).

## 3. Visual hierarchy
### Macro 2 km–200 m
Silhouette, watershed, ridge/valley rhythm, forest mass, open areas, landmarks and atmospheric depth.
### Meso 200–10 m
Vegetation communities, rock families, erosion, fallen timber, stream morphology, habitat patches and readable traversal corridors.
### Micro 10 m–1 mm
Bark, leaf damage, moss, lichen, fungal bodies, litter, roots, wetness, sediment, insect traces, seeds, pollen and particles.

No detail tier may contradict the tiers above it.

## 4. Ecological asset families
Assets are authored as families, never isolated props. Minimum family schema:
- juvenile / mature / senescent / dead state where biologically applicable
- 3–8 silhouette variants
- seasonal variants where applicable
- wet/dry response
- damage/decomposition states
- LOD chain
- collision proxy if later required
- semantic tags: species/group, habitat, moisture, substrate, succession stage

### Vegetation
Trees: trunk architecture, branch hierarchy, canopy density, bark age, exposed roots, cavities, deadwood.
Shrubs/herbs: clustered by ecological association rather than random scatter.
Ground cover: litter, moss, grasses, seedlings, fungi and exposed soil coupled to canopy and moisture.

### Geological system
Rock sets derive from a shared geological parent: formation, fracture direction, weathering, sediment and colonization. Loose stones inherit local parent material.

### Water system
Design separately: source, seep, temporary channel, stream, pool, river edge, saturated soil. Water modifies nearby material wetness, vegetation composition, erosion, debris and atmospheric effects.

### Below-ground world
Roots are a structural network, not glowing decoration. Define coarse roots, fine roots, root hairs conceptually, mycorrhizal zones, soil pores, organic horizons and decomposer hotspots. Any stylized visualization must remain distinguishable from literal biological anatomy.

### Insects and microorganisms
Use ecological guilds before species-level abundance: pollinators, decomposers, predators, herbivores, soil engineers, aquatic larvae, fungal/bacterial decomposers. Their visual presence follows habitat variables.

## 5. Environmental storytelling without fiction-first decoration
Every cluster answers: Why is this here? What produced it? What is changing it?
Examples: fallen tree -> canopy gap -> light increase -> seedlings -> fungi/decomposition -> insect activity; stream bend -> erosion bank + deposition bar -> moisture gradient -> vegetation shift.

## 6. Density without noise
Use nested clustering and negative space. High asset count is not equivalent to high fidelity. Deliberately preserve quiet surfaces and silhouette separation. Repetition must be broken by family variants, scale/rotation within biological limits, age/state, local terrain response and clustered distributions.

## 7. Lighting and atmosphere design
Lighting communicates ecology and scale rather than merely cinematic mood.
- canopy controls light fragmentation
- humidity controls haze and specular response
- wetness is spatially causal
- particles are locally motivated (pollen, spores, dust, insects, mist)
- night readability uses natural sources/contrast unless a visualization layer is explicitly active

Define authored profiles for dawn, midday, golden hour, blue hour, night, overcast, rain/post-rain and fog, but preserve material identity between profiles.

## 8. Map/worldbuilding agent — MAPA.ia
Responsibilities:
- watershed-first terrain grammar
- ecological cell map
- transition zones
- landmark hierarchy
- sightline/composition maps
- geological and hydrological plausibility
- density masks and exclusion zones
Deliverables are design maps/specifications, not playable map implementation.

## 9. 3D procedural agent — FORMA.ia
Responsibilities:
- Blender procedural asset-family specifications
- Geometry Nodes generators for rocks, deadwood, roots, plant distributions and controlled variation
- naming, pivots, scale, UV/material slots and export contracts
- LOD and proxy strategy
- asset-library reuse
No generator may erase ecological constraints for visual randomness.

## 10. Technical-art agent — TEJIDO.ia
Responsibilities:
- Godot-compatible scene/material contracts
- instancing strategy
- shader vocabulary
- environment profiles
- visibility/LOD/occlusion planning
- performance budgets and validation rules
This agent specifies integration but does not advance gameplay.

## 11. Ecology/science agent — BIOS.ia
Responsibilities:
- causal review of ecological assemblies
- species/guild compatibility
- seasonal and life-stage logic
- soil/root/fungal plausibility
- flagging visually attractive but biologically misleading designs

## 12. LEGAL.ia gate
Every external reference/resource receives provenance and license metadata before production use.
Allowed reference extraction: abstract principles such as density, contrast, pacing, polish, readability and production technique.
Forbidden: copying distinctive maps/layouts, proprietary assets, textures, audio, logos, characters, UI expression or other protected expression.
Third-party assets remain quarantined until license compatibility is recorded.

## 13. Autonomous asset contract
Proposed path convention:
assets/world/<domain>/<family>/<asset>/
Each family eventually carries source files plus a machine-readable manifest containing ID, version, provenance, license, ecological tags, dimensions, material slots, LODs, dependencies and validation status.

Naming:
MV_<DOMAIN>_<FAMILY>_<VARIANT>_<STATE>_<LOD>
Example: MV_TREE_OAK_A_MATURE_L0

## 14. Procedural pipeline
1. MAPA.ia defines physical/ecological masks.
2. BIOS.ia validates causal/ecological compatibility.
3. FORMA.ia generates constrained families and variation.
4. TEJIDO.ia defines engine-facing representation and budgets.
5. LEGAL.ia validates provenance/licenses/reference use.
6. Visual review checks macro -> meso -> micro coherence.
7. Approved methods/assets enter the reusable library.

## 15. Quality gates
An element is not approved merely because it looks good. It must pass:
- silhouette/readability
- ecological causality
- material consistency
- scale correctness
- family variation
- transition compatibility
- provenance/legal status
- future performance feasibility
- reuse/modularity

## 16. First design slice
Use one 250 m x 250 m watershed cell as the canonical design laboratory:
ridge -> mixed woodland -> canopy gap -> seep -> stream -> wet margin -> decaying log -> root/fungal micro-zone.
Produce the complete macro/meso/micro specification before expanding world area. This becomes the benchmark cell for all later regions.

## 17. Reusable library additions
- Ecology-first asset-family pattern.
- Three-scale macro/meso/micro review gate.
- Gradient biome transition rule.
- Provenance/license quarantine gate.
- Semantic asset manifests for procedural placement.
- Watershed-first terrain/world design.
- Causal environmental storytelling graph.
- Blender node tools packaged as reusable asset-library tools where appropriate.
- Godot high-instance vegetation strategy planned around instancing/MultiMesh, visibility and occlusion rather than thousands of independent scene objects.

## 18. Next design deliverables
A. Canonical watershed-cell map specification.
B. Tree family anatomy sheet and variation matrix.
C. Soil/root/fungi vertical-section specification.
D. Rock/geology family specification.
E. Stream morphology + wetness transition specification.
F. Environmental lighting/weather matrix.
G. Asset manifest schema v1.
H. Legal provenance register template.
I. Visual benchmark checklist for macro/meso/micro reviews.
