
"""
`module  JAC.Cascade
    ... a submodel of JAC that contains all methods to set-up and process (simple) atomic cascade computations.
"""
module Cascade

    using Dates, JLD, Printf, ..AutoIonization, ..Basics, ..Defaults, ..DecayYield, ..Radial, ..ManyElectron, ..Nuclear, ..PhotoEmission, 
                              ..PhotoIonization, ..Semiempirical, ..TableStrings

    
    """
    `abstract type Cascade.AbstractCascadeScheme` 
        ... defines an abstract type to distinguish different excitation, ionization and decay schemes of an atomic cascade; see also:
        
        + struct StepwiseDecayScheme       ... to represent a standard decay scheme, starting from one or several initial multiplets.
        + struct PhotonIonizationScheme    ... to represent a (prior) photoionization part of a cascade for given photon energies.
        + struct ElectronExcitationScheme  ... to represent a (prior) electron-impact excitation part of a cascade for given electron
                                               energies.
    """
    abstract type  AbstractCascadeScheme       end


    """
    `struct  Cascade.StepwiseDecayScheme  <:  Cascade.AbstractCascadeScheme`  
        ... a struct to represent (and generate) a mean-field orbital basis.

        + processes             ::Array{Basics.AtomicProcess,1} ... List of the atomic processes that are supported and should be included into the 
                                                                   cascade.
        + maxElectronLoss       ::Int64                         ... (Maximum) Number of electrons in which the initial- and final-state 
                                                                    configurations can differ from each other; this also determines the maximal steps 
                                                                    of any particular decay path.
        + NoShakeDisplacements  ::Int64                         ... Maximum number of electron displacements due to shake-up or shake-down processes 
                                                                    in any individual step of the cascade.
        + shakeFromShells       ::Array{Shell,1}                ... List of shells from which shake transitions may occur.
        + shakeToShells         ::Array{Shell,1}                ... List of shells into which shake transitions may occur.
    """
    struct   StepwiseDecayScheme  <:  Cascade.AbstractCascadeScheme
        processes               ::Array{Basics.AtomicProcess,1}
        maxElectronLoss         ::Int64
        NoShakeDisplacements    ::Int64
        shakeFromShells         ::Array{Shell,1}
        shakeToShells           ::Array{Shell,1}
    end


    """
    `Cascade.StepwiseDecayScheme()`  ... constructor for an 'default' instance of a Cascade.StepwiseDecayScheme.
    """
    function StepwiseDecayScheme()
        StepwiseDecayScheme([Radiative], 0, 0, Shell[], Shell[] )
    end


    # `Base.string(scheme::StepwiseDecayScheme)`  ... provides a String notation for the variable scheme::StepwiseDecayScheme.
    function Base.string(scheme::StepwiseDecayScheme)
        sa = "Stepwise decay (scheme) of an atomic cascade with:"
        return( sa )
    end


    # `Base.show(io::IO, scheme::StepwiseDecayScheme)`  ... prepares a proper printout of the scheme::StepwiseDecayScheme.
    function Base.show(io::IO, scheme::StepwiseDecayScheme)
        sa = Base.string(scheme);                print(io, sa, "\n")
        println(io, "processes:                  $(scheme.processes)  ")
        println(io, "maxElectronLoss:            $(scheme.maxElectronLoss)  ")
        println(io, "NoShakeDisplacements:       $(scheme.NoShakeDisplacements)  ")
        println(io, "shakeFromShells:            $(scheme.shakeFromShells)  ")
        println(io, "shakeToShells:              $(scheme.shakeToShells)  ")
    end


    """
    `struct  Cascade.PhotonIonizationScheme  <:  Cascade.AbstractCascadeScheme`  
        ... a struct to represent (and generate) a mean-field orbital basis.

        + processes             ::Array{Basics.AtomicProcess,1} ... List of the atomic processes that are supported and should be included into the 
                                                                    cascade.
        + maxPhotoElectrons     ::Int64                         ... (Maximum) Number of photo-electrons in which the initial- and (photo-ionized) 
                                                                    final-state configurations can differ from each other; this affects the number of
                                                                    ionized multiplets in the cascade.
        + photonEnergies        ::Array{Float64,1}              ... List of photon energies for which this photo-ionization scheme is to be calculated.
    """
    struct   PhotonIonizationScheme  <:  Cascade.AbstractCascadeScheme
        processes               ::Array{Basics.AtomicProcess,1}
        maxPhotoElectrons       ::Int64
        photonEnergies          ::Array{Float64,1}
    end


    """
    `Cascade.PhotonIonizationScheme()`  ... constructor for an 'default' instance of a Cascade.PhotonIonizationScheme.
    """
    function PhotonIonizationScheme()
        PhotonIonizationScheme([PhotoIonization], 0, Float64[] )
    end


    # `Base.string(scheme::PhotonIonizationScheme)`  ... provides a String notation for the variable scheme::PhotonIonizationScheme.
    function Base.string(scheme::PhotonIonizationScheme)
        sa = "Photo-ionization (scheme) as prior part of an atomic cascade:"
        return( sa )
    end


    # `Base.show(io::IO, scheme::PhotonIonizationScheme)`  ... prepares a proper printout of the scheme::PhotonIonizationScheme.
    function Base.show(io::IO, scheme::PhotonIonizationScheme)
        sa = Base.string(scheme);                print(io, sa, "\n")
        println(io, "processes:                  $(scheme.processes)  ")
        println(io, "maxPhotoElectrons:          $(scheme.maxPhotoElectrons)  ")
        println(io, "photonEnergies:             $(scheme.photonEnergies)  ")
    end


    """
    `struct  Cascade.ElectronExcitationScheme  <:  Cascade.AbstractCascadeScheme`  
        ... a struct to represent (and generate) a mean-field orbital basis.

        + processes             ::Array{Basics.AtomicProcess,1} ... List of the atomic processes that are supported and should be included into the 
                                                                    cascade.
        + electronEnergies      ::Array{Float64,1}              ... List of electron energies for which this electron-impact excitation scheme is 
                                                                    to be calculated.
    """
    struct   ElectronExcitationScheme  <:  Cascade.AbstractCascadeScheme
        processes               ::Array{Basics.AtomicProcess,1}
        electronEnergies        ::Array{Float64,1}
    end


    """
    `Cascade.ElectronExcitationScheme()`  ... constructor for an 'default' instance of a Cascade.ElectronExcitationScheme.
    """
    function ElectronExcitationScheme()
        ElectronExcitationScheme([Eimex], Float64[] )
    end


    # `Base.string(scheme::ElectronExcitationScheme)`  ... provides a String notation for the variable scheme::ElectronExcitationScheme.
    function Base.string(scheme::ElectronExcitationScheme)
        sa = "Electron-impact excitation (scheme) as prior part of an atomic cascade:"
        return( sa )
    end


    # `Base.show(io::IO, scheme::ElectronExcitationScheme)`  ... prepares a proper printout of the scheme::ElectronExcitationScheme.
    function Base.show(io::IO, scheme::ElectronExcitationScheme)
        sa = Base.string(scheme);                 print(io, sa, "\n")
        println(io, "processes:                   $(scheme.processes)  ")
        println(io, "electronEnergies:            $(scheme.electronEnergies)  ")
    end
    

    """
    `abstract type Cascade.AbstractCascadeApproach` 
        ... defines an abstract and a number of singleton types for the computational approach/model that is applied to 
            generate and evaluate a cascade.

      + struct AverageSCA         
        ... to evaluate the level structure and transitions of all involved levels in single-configuration approach but 
            without configuration interaction and from just a single orbital set.
            
      + struct SCA                
        ... to evaluate the level structure and transitions of all involved levels in single-configuration approach but 
            by calculating all fine-structure resolved transitions.
    """
    abstract type  AbstractCascadeApproach                   end
    struct         AverageSCA  <:  AbstractCascadeApproach   end
    struct         SCA         <:  AbstractCascadeApproach   end
    struct         UserMCA     <:  AbstractCascadeApproach   end
    


    """
    `struct  Cascade.Block`  
        ... defines a type for an individual block of configurations that are treatet together within the cascade. Such an block is given 
            by a list of configurations that may occur as initial- or final-state configurations in some step of the canscade and that are 
            treated together in a single multiplet to allow for configuration interaction but to avoid 'double counting' of individual levels.

        + NoElectrons     ::Int64                     ... Number of electrons in this block.
        + confs           ::Array{Configuration,1}    ... List of one or several configurations that define the multiplet.
        + hasMultiplet    ::Bool                      ... true if the (level representation in the) multiplet has already been computed and
                                                          false otherwise.
        + multiplet       ::Multiplet                 ... Multiplet of the this block.
    """
    struct  Block
        NoElectrons       ::Int64
        confs             ::Array{Configuration,1} 
        hasMultiplet      ::Bool
        multiplet         ::Multiplet  
    end 


    """
    `Cascade.Block()`  ... constructor for an 'empty' instance of a Cascade.Block.
    """
    function Block()
        Block( )
    end


    # `Base.show(io::IO, block::Cascade.Block)`  ... prepares a proper printout of the variable block::Cascade.Block.
    function Base.show(io::IO, block::Cascade.Block) 
        println(io, "NoElectrons:        $(block.NoElectrons)  ")
        println(io, "confs :             $(block.confs )  ")
        println(io, "hasMultiplet:       $(block.hasMultiplet)  ")
        println(io, "multiplet:          $(block.multiplet)  ")
    end


    """
    `struct  Cascade.Step`  
        ... defines a type for an individual step of an excitation and/or decay cascade. Such an individual step is given by a well-defined 
            process, such as Auger, PhotoEmission, or others and two lists of initial- and final-state configuration that are (each) treated 
            together in a multiplet to allow for configuration interaction but to avoid 'double counting' of individual levels.

        + process          ::JBasics.AtomicProcess         ... Atomic process that 'acts' in this step of the cascade.
        + settings         ::Union{PhotoEmission.Settings, AutoIonization.Settings, PhotoIonization.Settings}        
                                                       ... Settings for this step of the cascade.
        + initialConfigs   ::Array{Configuration,1}    ... List of one or several configurations that define the initial-state multiplet.
        + finalConfigs     ::Array{Configuration,1}    ... List of one or several configurations that define the final-state multiplet.
        + initialMultiplet ::Multiplet                 ... Multiplet of the initial-state levels of this step of the cascade.
        + finalMultiplet   ::Multiplet                 ... Multiplet of the final-state levels of this step of the cascade.
    """
    struct  Step
        process            ::Basics.AtomicProcess
        settings           ::Union{PhotoEmission.Settings, AutoIonization.Settings, PhotoIonization.Settings}
        initialConfigs     ::Array{Configuration,1}
        finalConfigs       ::Array{Configuration,1}
        initialMultiplet   ::Multiplet
        finalMultiplet     ::Multiplet
    end 


    """
    `Cascade.Step()`  ... constructor for an 'empty' instance of a Cascade.Step.
    """
    function Step()
        Step( Basics.NoProcess, PhotoEmission.Settings, Configuration[], Configuration[], Multiplet(), Multiplet())
    end


    # `Base.show(io::IO, step::Cascade.Step)`  ... prepares a proper printout of the variable step::Cascade.Step.
    function Base.show(io::IO, step::Cascade.Step) 
        println(io, "process:                $(step.process)  ")
        println(io, "settings:               $(step.settings)  ")
        println(io, "initialConfigs:         $(step.initialConfigs)  ")
        println(io, "finalConfigs:           $(step.finalConfigs)  ")
        println(io, "initialMultiplet :      $(step.initialMultiplet )  ")
        println(io, "finalMultiplet:         $(step.finalMultiplet)  ")
    end


    """
    `struct  Cascade.Computation`  
        ... defines a type for a cascade computation, i.e. for the computation of a whole excitation and/or decay cascade. The data 
            from this computation can be modified, adapted and refined to the practical needs before the actual computations are 
            carried out. Initially, this struct contains the physical metadata about the cascade to be calculated but gets enlarged 
            in course of the computation to keep also wave functions, level multiplets, etc.

        + name               ::String                          ... A name for the cascade
        + nuclearModel       ::Nuclear.Model                   ... Model, charge and parameters of the nucleus.
        + grid               ::Radial.Grid                     ... The radial grid to be used for the computation.
        + asfSettings        ::AsfSettings                     ... Provides the settings for the SCF process.
        + scheme             ::Cascade.AbstractCascadeScheme   ... Scheme of the atomic cascade (photoionization, decay, ...)
        + approach           ::Cascade.AbstractCascadeApproach ... Computational approach/model that is applied to generate and evaluate the 
                                                                   cascade; possible approaches are: {'single-configuration', ...}
        + initialConfs       ::Array{Configuration,1}          ... List of one or several configurations that contain the level(s) from which the 
                                                                   cascade starts.
        + initialMultiplets  ::Array{Multiplet,1}              ... List of one or several (initial) multiplets; either initialConfs 'xor'
                                                                   initialMultiplets can be specified for a cascade computation.
    """
    struct  Computation
        name                 ::String
        nuclearModel         ::Nuclear.Model
        grid                 ::Radial.Grid
        asfSettings          ::AsfSettings
        scheme               ::Cascade.AbstractCascadeScheme 
        approach             ::Cascade.AbstractCascadeApproach
        initialConfigs       ::Array{Configuration,1}
        initialMultiplets    ::Array{Multiplet,1} 
    end 


    """
    `Cascade.Computation()`  ... constructor for an 'default' instance of a Cascade.Computation.
    """
    function Computation()
        Computation("Default cascade computation",  Nuclear.Model(10.), Radial.Grid(), AsfSettings(), Cascade.StepwiseDecayScheme(), 
                    Cascade.AverageSCA(), Configuration[], Multiplet[] )
    end


    """
    `Cascade.Computation(comp::Cascade.Computation;`
        
                name=..,               nuclearModel=..,             grid=..,              asfSettings=..,     
                scheme=..,             approach=..,                 initialConfigs=..,    initialMultiplets=..)
                
        ... constructor for re-defining the computation::Cascade.Computation.
    """
    function Computation(comp::Cascade.Computation;                              
        name::Union{Nothing,String}=nothing,                                  nuclearModel::Union{Nothing,Nuclear.Model}=nothing,
        grid::Union{Nothing,Radial.Grid}=nothing,                             asfSettings::Union{Nothing,AsfSettings}=nothing,  
        scheme::Union{Nothing,Cascade.AbstractCascadeScheme}=nothing,         approach::Union{Nothing,Cascade.AbstractCascadeApproach}=nothing, 
        initialConfigs::Union{Nothing,Array{Configuration,1}}=nothing,        initialMultiplets::Union{Nothing,Array{Multiplet,1}}=nothing)
        
        if  initialConfigs != nothing   &&   initialMultiplets != nothing   
            error("Only initialConfigs=..  'xor'  initialMultiplets=..  can be specified for a Cascade.Computation().")
        end

        if  name                 == nothing   namex                 = comp.name                    else  namex = name                                   end 
        if  nuclearModel         == nothing   nuclearModelx         = comp.nuclearModel            else  nuclearModelx = nuclearModel                   end 
        if  grid                 == nothing   gridx                 = comp.grid                    else  gridx = grid                                   end 
        if  asfSettings          == nothing   asfSettingsx          = comp.asfSettings             else  asfSettingsx = asfSettings                     end 
        if  scheme               == nothing   schemex               = comp.scheme                  else  schemex = scheme                               end 
        if  approach             == nothing   approachx             = comp.approach                else  approachx = approach                           end 
        if  initialConfigs       == nothing   initialConfigsx       = comp.initialConfigs          else  initialConfigsx = initialConfigs               end 
        if  initialMultiplets    == nothing   initialMultipletsx    = comp.initialMultiplets       else  initialMultipletsx = initialMultiplets         end
    	
    	Computation(namex, nuclearModelx, gridx, asfSettingsx, schemex, approachx, initialConfigsx, initialMultipletsx)
    end


    # `Base.string(comp::Cascade.Computation)`  ... provides a String notation for the variable comp::Cascade.Computation.
    function Base.string(comp::Cascade.Computation)
        if        typeof(comp.scheme) == Cascade.StepwiseDecayScheme     sb = "stepwise decay scheme"
        elseif    typeof(comp.scheme) == Cascade.PhotonIonizationScheme  sb = "(prior) photo-ionization scheme"
        else      error("unknown typeof(comp.scheme)")
        end
        
        sa = "Cascade computation   $(comp.name)  for a $sb,  in $(comp.approach) approach as well as "
        sa = sa * "for Z = $(comp.nuclearModel.Z) and initial configurations: \n "
        if  comp.initialConfigs    != Configuration[]  for  config  in  comp.initialConfigs     sa = sa * string(config) * ",  "     end     end
        if  comp.initialMultiplets != Multiplet[]      
            for  mp      in  comp.initialMultiplets  sa = sa * mp.name * " with " * string(length(mp.levels)) * " levels,  "         end     end
        return( sa )
    end


    # `Base.show(io::IO, comp::Cascade.Computation)`  ... prepares a proper printout comp::Cascade.Computation.
    function Base.show(io::IO, comp::Cascade.Computation)
        sa = Base.string(comp)
        sa = sa * "\n ... in addition, the following parameters/settings are defined: ";       print(io, sa, "\n")
        println(io, "> cascade scheme:           $(comp.scheme)  ")
        println(io, "> nuclearModel:             $(comp.nuclearModel)  ")
        println(io, "> grid:                     $(comp.grid)  ")
        println(io, "> asfSettings:            \n$(comp.asfSettings) ")
    end
    
    #######################################################################################################################################
    #######################################################################################################################################
    #######################################################################################################################################


    """
    abstract type  Cascade.AbstractData`  
        ... defines an abstract type to distinguish different output data of a cascade computation; see also:

        + struct DecayData       ... to comprise the amplitudes/rates from a stepswise decay cascade.
        + struct PhotoIonData    ... to comprise the amplitudes/rates from a photo-ionization part of a cascade.
    """
    abstract type  AbstractData      end


    """
    `struct  Cascade.DecayData  <:  Cascade.AbstractData`  ... defines a type for an atomic cascade, i.e. lists of radiative and Auger lines.

        + name           ::String                               ... A name for the cascade.
        + linesR         ::Array{PhotoEmission.Line,1}          ... List of radiative lines.
        + linesA         ::Array{AutoIonization.Line,1}         ... List of Auger lines.
    """  
    struct  DecayData  <:  Cascade.AbstractData
        linesR           ::Array{PhotoEmission.Line,1}
        linesA           ::Array{AutoIonization.Line,1}
    end 


    """
    `Cascade.DecayData()`  ... (simple) constructor for cascade  decay data.
    """
    function DecayData()
        DecayData(Array{PhotoEmission.Line,1}[], Array{AutoIonization.Line,1}[] )
    end


    # `Base.show(io::IO, data::Cascade.DecayData)`  ... prepares a proper printout of the variable data::Cascade.DecayData.
    function Base.show(io::IO, data::Cascade.DecayData) 
        println(io, "linesR:                  $(data.linesR)  ")
        println(io, "linesA:                  $(data.linesA)  ")
    end


    """
    `struct  Cascade.PhotoIonData  <:  Cascade.AbstractData`  ... defines a type for an atomic cascade, i.e. lists of photoionization lines.

        + photonEnergy   ::Float64                              ... Photon energy for this (part of the) cascade.
        + linesP         ::Array{PhotoIonization.Line,1}        ... List of photoionization lines.
    """  
    struct  PhotoIonData  <:  Cascade.AbstractData
        photonEnergy     ::Float64
        linesP           ::Array{PhotoIonization.Line,1}
    end 


    """
    `Cascade.PhotoIonData()`  ... (simple) constructor for cascade photo-ionization data.
    """
    function PhotoIonData()
        PhotoIonData(0., Array{PhotoIonization.Line,1}[] )
    end


    # `Base.show(io::IO, data::Cascade.PhotoIonData)`  ... prepares a proper printout of the variable data::Cascade.PhotoIonData.
    function Base.show(io::IO, data::Cascade.PhotoIonData) 
        println(io, "photonEnergy:            $(data.photonEnergy)  ")
        println(io, "linesP:                  $(data.linesP)  ")
    end
    

    #######################################################################################################################################
    #######################################################################################################################################
    #######################################################################################################################################

    
    """
    `abstract type  Cascade.AbstractSimulationProperty`  
        ... defines an abstract and various singleton types for the different properties that can be obtained from the simulation of cascade data.

        + struct IonDistribution         ... simulate the 'ion distribution' as it is found after all cascade processes are completed.
        + struct FinalLevelDistribution  ... simulate the 'final-level distribution' as it is found after all cascade processes are completed.
        + struct DecayPathes             ... determine the major 'decay pathes' of the cascade.
        + struct ElectronIntensities     ... simulate the electron-line intensities as function of electron energy.
        + struct PhotonIntensities       ... simulate  the photon-line intensities as function of electron energy. 
        + struct ElectronCoincidence     ... simulate electron-coincidence spectra.
    """
    abstract type  AbstractSimulationProperty                              end
    struct   IonDistribution              <:  AbstractSimulationProperty   end
    struct   FinalLevelDistribution       <:  AbstractSimulationProperty   end
    struct   DecayPathes                  <:  AbstractSimulationProperty   end
    struct   ElectronIntensities          <:  AbstractSimulationProperty   end
    struct   PhotonIntensities            <:  AbstractSimulationProperty   end
    struct   ElectronCoincidence          <:  AbstractSimulationProperty   end


    """
    abstract type  Cascade.AbstractSimulationMethod`  
        ... defines a enumeration for the various methods that can be used to run the simulation of cascade data.

        + struct ProbPropagation     ... to propagate the (occupation) probabilites of the levels until no further changes occur.
        + struct MonteCarlo          ... to simulate the cascade decay by a Monte-Carlo approach of possible pathes (not yet considered).
        + struct RateEquations       ... to solve the cascade by a set of rate equations (not yet considered).
    """
    abstract type  AbstractSimulationMethod                  end
    struct   ProbPropagation  <:  AbstractSimulationMethod   end
    struct   MonteCarlo       <:  AbstractSimulationMethod   end
    struct   RateEquations    <:  AbstractSimulationMethod   end


    """
    `struct  Cascade.SimulationSettings`  ... defines settings for performing the simulation of some cascade (data).

        + minElectronEnergy   ::Float64     ... Minimum electron energy for the simulation of electron spectra.
        + maxElectronEnergy   ::Float64     ... Maximum electron energy for the simulation of electron spectra.
        + minPhotonEnergy     ::Float64     ... Minimum photon energy for the simulation of electron spectra.
        + maxPhotonEnergy     ::Float64     ... Maximum photon energy for the simulation of electron spectra..
        + initialOccupations  ::Array{Tuple{Int64,Float64},1}   ... List of one or several (tupels of) levels in the overall 
                                                cascade tree together with their relative population.
    """
    struct  SimulationSettings
        minElectronEnergy     ::Float64
        maxElectronEnergy     ::Float64
        minPhotonEnergy       ::Float64
        maxPhotonEnergy       ::Float64
        initialOccupations    ::Array{Tuple{Int64,Float64},1} 
    end 


    """
    `Cascade.SimulationSettings()`  ... constructor for an 'empty' instance of a Cascade.Block.
    """
    function SimulationSettings()
        SimulationSettings(0., 1.0e6,  0., 1.0e6, [(1, 1.0)] )
    end


    # `Base.show(io::IO, settings::SimulationSettings)`  ... prepares a proper printout of the variable settings::SimulationSettings.
    function Base.show(io::IO, settings::SimulationSettings) 
        println(io, "minElectronEnergy:        $(settings.minElectronEnergy)  ")
        println(io, "maxElectronEnergy:        $(settings.maxElectronEnergy)  ")
        println(io, "minPhotonEnergy:          $(settings.minPhotonEnergy)  ")
        println(io, "maxPhotonEnergy:          $(settings.maxPhotonEnergy)  ")
        println(io, "initialOccupations:       $(settings.initialOccupations)  ")
    end


    """
    `struct  Cascade.Simulation`  ... defines a simulation on some given cascade (data).

        + name            ::String                                      ... Name of the simulation
        + properties      ::Array{Cascade.AbstractSimulationProperty,1} ... Properties that are considered in this simulation of the cascade (data).
        + method          ::Cascade.AbstractSimulationMethod            ... Method that is used in the cascade simulation; cf. Cascade.SimulationMethod.
        + settings        ::Cascade.SimulationSettings                  ... Settings for performing these simulations.
        + computationData ::Array{Dict{String,Any},1}                   ... Date on which the simulations are performed
    """
    struct  Simulation
        name              ::String
        properties        ::Array{Cascade.AbstractSimulationProperty,1}
        method            ::Cascade.AbstractSimulationMethod
        settings          ::Cascade.SimulationSettings 
        computationData   ::Array{Dict{String,Any},1}
    end 


    """
    `Cascade.Simulation()`  ... constructor for an 'default' instance of a Cascade.Simulation.
    """
    function Simulation()
        Simulation("Default cascade simulation", Cascade.AbstractSimulationProperty[], Cascade.ProbPropagation(), 
                   Cascade.SimulationSettings(), Array{Dict{String,Any},1}[] )
    end


    """
    `Cascade.Simulation(sim::Cascade.Simulation;`
        
                name=..,               properties=..,             method=..,              settings=..,     computationData=.. )
                
        ... constructor for re-defining the computation::Cascade.Simulation.
    """
    function Simulation(sim::Cascade.Simulation;                              
        name::Union{Nothing,String}=nothing,                                  properties::Union{Nothing,Array{Cascade.AbstractSimulationProperty,1}}=nothing,
        method::Union{Nothing,Cascade.AbstractSimulationMethod}=nothing,      settings::Union{Nothing,Cascade.SimulationSettings}=nothing,    
        computationData::Union{Nothing,Array{Dict{String,Any},1}}=nothing )
 
        if  name            == nothing   namex            = sim.name              else  namex = name                          end 
        if  properties      == nothing   propertiesx      = sim.properties        else  propertiesx = properties              end 
        if  method          == nothing   methodx          = sim.method            else  methodx = method                      end 
        if  settings        == nothing   settingsx        = sim.settings          else  settingsx = settings                  end 
        if  computationData == nothing   computationDatax = sim.computationData   else  computationDatax = computationData    end 
    	
    	Simulation(namex, propertiesx, methodx, settingsx, computationDatax)
    end


    # `Base.show(io::IO, simulation::Cascade.Simulation)`  ... prepares a proper printout of the variable simulation::Cascade.Simulation.
    function Base.show(io::IO, simulation::Cascade.Simulation) 
        println(io, "name:              $(simulation.name)  ")
        println(io, "properties:        $(simulation.properties)  ")
        println(io, "method:            $(simulation.method)  ")
        println(io, "computationData:   ... based on $(length(simulation.computationData)) cascade data sets ")
        println(io, "> settings:      \n$(simulation.settings)  ")
    end


    """
    `struct  Cascade.LineIndex`  ... defines a line index with regard to the various lineLists of data::Cascade.LineIndex.

        + lineSet      ::Cascade.AbstractData    ... refers to the data set for which this index is defined.
        + process      ::Basics.AtomicProcess    ... refers to the particular lineList of cascade (data).
        + index        ::Int64                   ... index of the corresponding line.
    """
    struct  LineIndex
        lineSet        ::Cascade.AbstractData 
        process        ::Basics.AtomicProcess
        index          ::Int64 
    end 


    # `Base.show(io::IO, index::Cascade.LineIndex)`  ... prepares a proper printout of the variable index::Cascade.LineIndex.
    function Base.show(io::IO, index::Cascade.LineIndex) 
        println(io, "lineSet (typeof):      $(typeof(index.lineSet))  ")
        println(io, "process:               $(index.process)  ")
        println(io, "index:                 $(index.index)  ")
    end


    """
    `mutable struct  Cascade.Level`  ... defines a level specification for dealing with cascade transitions.

        + energy       ::Float64                     ... energy of the level.
        + J            ::AngularJ64                  ... total angular momentum of the level
        + parity       ::Basics.Parity               ... total parity of the level
        + NoElectrons  ::Int64                       ... total number of electrons of the ion to which this level belongs.
        + relativeOcc  ::Float64                     ... relative occupation  
        + parents      ::Array{Cascade.LineIndex,1}  ... list of parent lines that (may) populate the level.     
        + daugthers    ::Array{Cascade.LineIndex,1}  ... list of daugther lines that (may) de-populate the level.     
    """
    mutable struct  Level
        energy         ::Float64 
        J              ::AngularJ64 
        parity         ::Basics.Parity 
        NoElectrons    ::Int64 
        relativeOcc    ::Float64 
        parents        ::Array{Cascade.LineIndex,1} 
        daugthers      ::Array{Cascade.LineIndex,1} 
    end 


    # `Base.show(io::IO, level::Cascade.Level)`  ... prepares a proper printout of the variable level::Cascade.Level.
    function Base.show(io::IO, level::Cascade.Level) 
        println(io, "energy:        $(level.energy)  ")
        println(io, "J:             $(level.J)  ")
        println(io, "parity:        $(level.parity)  ")
        println(io, "NoElectrons:   $(level.NoElectrons)  ")
        println(io, "relativeOcc:   $(level.relativeOcc)  ")
        println(io, "parents:       $(level.parents)  ")
        println(io, "daugthers:     $(level.daugthers)  ")
    end
    
    
    """
    `Base.:(==)(leva::Cascade.Level, levb::Cascade.Level)`  ... returns true if both levels are equal and false otherwise.
    """
    function  Base.:(==)(leva::Cascade.Level, levb::Cascade.Level)
        if  leva.energy == levb.energy   &&   leva.J == levb.J  && leva.parity == levb.parity  && leva.NoElectrons == levb.NoElectrons 
                return( true )
        else    return( false )
        end
    end
    
    
    include("module-Cascade-inc-computations.jl")
    include("module-Cascade-inc-simulations.jl")
    

end # module


