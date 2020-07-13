
"""
`module  JAC.PhotoEmission`  
    ... a submodel of JAC that contains all methods for computing Einstein coefficients, oscillator strength, etc. between 
        some initial and final-state multiplets.    ***done***
"""
module PhotoEmission

    using Printf, ..AngularMomentum, ..Basics, ..Defaults, ..InteractionStrength, ..ManyElectron, ..Radial, ..TableStrings
    ##x global JAC_counter = 0


    """
    `struct  PhotoEmission.Settings`  ... defines a type for the details and parameters of computing radiative lines.

        + multipoles              ::Array{EmMultipoles}     ... Specifies the (radiat. field) multipoles to be included.
        + gauges                  ::Array{UseGauge}         ... Gauges to be included into the computations.
        + calcAnisotropy          ::Bool                    ... True, if the anisotropy (structure) functions are to be 
                                                                calculated and false otherwise 
        + printBefore             ::Bool                    ... True, if all energies and lines are printed before comput.
        + lineSelection           ::LineSelection          ... Specifies the selected levels, if any.
        + photonEnergyShift       ::Float64                 ... An overall energy shift for all photon energies.
        + mimimumPhotonEnergy     ::Float64                 ... minimum transition energy for which (photon) transitions 
                                                                are included into the computation.
        + maximumPhotonEnergy     ::Float64                 ... maximum transition energy for which (photon) transitions 
                                                                are included.
    """
    struct Settings 
        multipoles                ::Array{EmMultipole,1}
        gauges                    ::Array{UseGauge}
        calcAnisotropy            ::Bool         
        printBefore               ::Bool 
        lineSelection             ::LineSelection 
        photonEnergyShift         ::Float64
        mimimumPhotonEnergy       ::Float64   
        maximumPhotonEnergy       ::Float64     
    end 


    """
    `PhotoEmission.Settings()`  ... constructor for the default values of radiative line computations
    """
    function Settings()
        Settings(EmMultipole[E1], UseGauge[Basics.UseCoulomb], false, false, LineSelection(), 0., 0., 10000.)
    end


    """
    `PhotoEmission.Settings(set::PhotoEmission.Settings;`
    
            multipoles::=..,        gauges=..,          calcAnisotropy=..,          printBefore=..,
            line=..,         selectedLines=..,   photonEnergyShift=..,       mimimumPhotonEnergy=.., 
            maximumPhotonEnergy=..) 
                        
        ... constructor for modifying the given PhotoEmission.Settings by 'overwriting' the previously selected parameters.
    """
    function Settings(set::PhotoEmission.Settings;    
        multipoles::Union{Nothing,Array{EmMultipole,1}}=nothing,    gauges::Union{Nothing,Array{UseGauge}}=nothing,
        calcAnisotropy::Union{Nothing,Bool}=nothing,                printBefore::Union{Nothing,Bool}=nothing,
        lineSelection::Union{Nothing,LineSelection}=nothing, 
        photonEnergyShift::Union{Nothing,Float64}=nothing,          mimimumPhotonEnergy::Union{Nothing,Float64}=nothing, 
        maximumPhotonEnergy::Union{Nothing,Float64}=nothing)
        
        if  multipoles          == nothing   multipolesx          = set.multipoles              else  multipolesx          = multipoles            end 
        if  gauges              == nothing   gaugesx              = set.gauges                  else  gaugesx              = gauges                end 
        if  calcAnisotropy      == nothing   calcAnisotropyx      = set.calcAnisotropy          else  calcAnisotropyx      = calcAnisotropy        end 
        if  printBefore         == nothing   printBeforex         = set.printBefore             else  printBeforex         = printBefore           end 
        if  lineSelection       == nothing   lineSelectionx       = set.lineSelection           else  lineSelectionx       = lineSelection         end 
        if  photonEnergyShift   == nothing   photonEnergyShiftx   = set.photonEnergyShift       else  photonEnergyShiftx   = photonEnergyShift     end 
        if  mimimumPhotonEnergy == nothing   mimimumPhotonEnergyx = set.mimimumPhotonEnergy     else  mimimumPhotonEnergyx = mimimumPhotonEnergy   end 
        if  maximumPhotonEnergy == nothing   maximumPhotonEnergyx = set.maximumPhotonEnergy     else  maximumPhotonEnergyx = maximumPhotonEnergy   end 
        
        Settings( multipolesx, gaugesx, calcAnisotropyx, printBeforex, lineSelectionx,    ## selectLinesx, selectedLinesx, 
                  photonEnergyShiftx, mimimumPhotonEnergyx, maximumPhotonEnergyx)
    end


    # `Base.show(io::IO, settings::PhotoEmission.Settings)`  ... prepares a proper printout of the variable settings::PhotoEmissionSettings.
    function Base.show(io::IO, settings::PhotoEmission.Settings) 
        println(io, "multipoles:             $(settings.multipoles)  ")
        println(io, "gauges:                 $(settings.gauges)  ")
        println(io, "calcAnisotropy:         $(settings.calcAnisotropy)  ")
        println(io, "printBefore:            $(settings.printBefore)  ")
        println(io, "lineSelection:          $(settings.lineSelection)  ")
        println(io, "photonEnergyShift:      $(settings.photonEnergyShift)  ")
        println(io, "mimimumPhotonEnergy:    $(settings.mimimumPhotonEnergy)  ")
        println(io, "maximumPhotonEnergy:    $(settings.maximumPhotonEnergy)  ")
    end


    """
    `struct  PhotoEmission.Channel`  
        ... defines a type for a single radiative emission/absorption channel that specifies the multipole, gauge and amplitude.

        + multipole         ::EmMultipole        ... Multipole of the photon emission/absorption.
        + gauge             ::EmGauge            ... Gauge for dealing with the (coupled) radiation field.
        + amplitude         ::Complex{Float64}   ... Amplitude of this multiple channel.
    """
    struct Channel 
        multipole           ::EmMultipole
        gauge               ::EmGauge
        amplitude           ::Complex{Float64}
    end 


    # `Base.show(io::IO, channel::PhotoEmission.Channel)`  ... prepares a proper printout of the variable channel::PhotoEmission.Channel.
    function Base.show(io::IO, channel::PhotoEmission.Channel) 
        print(io, "PhotoEmission.Channel($(channel.multipole), $(channel.gauge), amp = $(channel.amplitude)) ") 
    end


    """
    `struct  PhotoEmission.Line`  
        ... defines a type for a radiative line that may include the definition of sublines and their corresponding amplitudes.

        + initialLevel   ::Level               ... initial-(state) level
        + finalLevel     ::Level               ... final-(state) level
        + omega          ::Float64             ... Transition frequency of this line; can be shifted w.r.t. the level energies.
        + photonRate     ::EmProperty          ... Total rate of this line.
        + angularBeta    ::EmProperty          ... Angular beta_2 coefficient.
        + hasSublines    ::Bool                ... Determines whether the sublines are defined in terms of their multipolarity, amplitude, or not.
        + channels       ::Array{PhotoEmission.Channel,1}  ... List of radiative (photon) channels
    """
    struct  Line
        initialLevel     ::Level
        finalLevel       ::Level
        omega            ::Float64
        photonRate       ::EmProperty
        angularBeta      ::EmProperty
        hasSublines      ::Bool
        channels         ::Array{PhotoEmission.Channel,1}
    end 


    """
    `PhotoEmission.Line(initialLevel::Level, finalLevel::Level, photonRate::Float64)`  
        ... constructor an radiative line between a specified initial and final level.
    """
    function Line(initialLevel::Level, finalLevel::Level, omega::Float64, photonRate::EmProperty)
       Line(initialLevel, finalLevel, omega, photonRate, EmProperty(0., 0.), false, 0, PhotoEmission.Channel[])
    end


    # `Base.show(io::IO, line::PhotoEmissionLine)`  ... prepares a proper printout of the variable line::PhotoEmission.Line.
    function Base.show(io::IO, line::PhotoEmission.Line) 
        println(io, "initialLevel:         $(line.initialLevel)  ")
        println(io, "finalLevel:           $(line.finalLevel)  ")
        println(io, "omega:                $(line.omega)  ")
        println(io, "photonRate:           $(line.photonRate)  ")
        println(io, "angularBeta:          $(line.angularBeta)  ")
        println(io, "hasSublines:          $(line.hasSublines)  ")
        println(io, "channels:             $(line.channels)  ")
    end


    """
    `PhotoEmission.amplitude(kind::String, Mp::EmMultipole, gauge::EmGauge, omega::Float64, finalLevel::Level, initialLevel::Level, 
                             grid::Radial.Grid; display::Bool=false, printout::Bool=false)`  
        ... to compute the kind = (absorption or emission) amplitude  <alpha_f J_f || O^(Mp, kind) || alpha_i J_i> for the 
            interaction with  photon of multipolarity Mp and for the given transition energy and gauge. A value::ComplexF64 is 
            returned. The amplitude value is printed to screen if display=true.
    """
    function amplitude(kind::String, Mp::EmMultipole, gauge::EmGauge, omega::Float64, finalLevel::Level, initialLevel::Level, 
                       grid::Radial.Grid; display::Bool=false, printout::Bool=false)
        
        if      kind == "emission"
        #-------------------------
            nf = length(finalLevel.basis.csfs);    ni = length(initialLevel.basis.csfs)
            if  printout   printstyled("Compute radiative $(Mp) matrix of dimension $nf x $ni in the initial- and final-state bases " *
                                       "for the transition [$(initialLevel.index)-$(finalLevel.index)] ... ", color=:light_green)    end
            matrix = zeros(ComplexF64, nf, ni)
            #
            for  r = 1:nf
                ##x @show r, finalLevel.basis.csfs[r].J, finalLevel.J, finalLevel.basis.csfs[r].parity, finalLevel.parity
                if  finalLevel.basis.csfs[r].J != finalLevel.J          ||  finalLevel.basis.csfs[r].parity   != finalLevel.parity    continue    end 
                for  s = 1:ni
                    if  initialLevel.basis.csfs[s].J != initialLevel.J  ||  initialLevel.basis.csfs[s].parity != initialLevel.parity  continue    end 
                    wa = Basics.compute("angular coefficients: 1-p, Grasp92", 0, Mp.L, finalLevel.basis.csfs[r], initialLevel.basis.csfs[s])
                    ##x @show finalLevel.basis  ## .csfs[r]
                    ##x @show initialLevel.basis  ## .csfs[s]
                    me = 0.
                    ##x println("Enter loop ... r=$r   s=$s  length(wa) = $(length(wa))")
                    for  coeff in wa
                        ja = Basics.subshell_2j(finalLevel.basis.orbitals[coeff.a].subshell)
                        jb = Basics.subshell_2j(initialLevel.basis.orbitals[coeff.b].subshell)
                        MbaCheng  = InteractionStrength.MbaEmissionCheng(Mp, gauge, omega, finalLevel.basis.orbitals[coeff.a],  
                                                                                                 initialLevel.basis.orbitals[coeff.b], grid)
                        me = me + coeff.T * MbaCheng  ## sqrt( (ja + 1)/(jb + 1) ) * ##   0.707106781186548 *
                    end
                    ##x println("r = $r, s = $s, me = $me")
                    matrix[r,s] = me
                end
            end 
            if  printout   printstyled("done. \n", color=:light_green)    end
            amplitude = transpose(finalLevel.mc) * matrix * initialLevel.mc 
            #
            #
        elseif  kind == "absorption"
        #---------------------------
            iLevel = finalLevel;   fLevel = initialLevel
            amplitude = PhotoEmission.amplitude("emission", Mp, gauge, omega, fLevel, iLevel, grid, printout=printout) 
            amplitude = conj(amplitude)
        else    error("stop a")
        end
        
        if  display  
            println("    < level=$(finalLevel.index) [J=$(finalLevel.J)$(string(finalLevel.parity))] ||" *
                    " O^($Mp, $kind) ($omega a.u., $gauge) ||" *
                    " $(initialLevel.index) [$(initialLevel.J)$(string(initialLevel.parity))] >  = $amplitude  ")
        end
        
        return( amplitude )
    end


    """
    `PhotoEmission.computeLines(finalMultiplet::Multiplet, initialMultiplet::Multiplet, grid::Radial.Grid, settings::PhotoEmission.Settings; 
                                output=true)`  
        ... to compute the radiative transition amplitudes and all properties as requested by the given settings. A list of 
            lines::Array{PhotoEmission.Lines} is returned.
    """
    function  computeLines(finalMultiplet::Multiplet, initialMultiplet::Multiplet, grid::Radial.Grid, settings::PhotoEmission.Settings; output=true) 
        # Define a common subshell list for both multiplets
        subshellList = Basics.generate("subshells: ordered list for two bases", finalMultiplet.levels[1].basis, initialMultiplet.levels[1].basis)
        Defaults.setDefaults("relativistic subshell list", subshellList; printout=true)
        ##x Defaults.setDefaults("standard grid", grid)
        println("")
        printstyled("PhotoEmission.computeLines(): The computation of the transition amplitudes and properties starts now ... \n", color=:light_green)
        printstyled("-------------------------------------------------------------------------------------------------------- \n", color=:light_green)
        println("")
        ##x println("basis = $(finalMultiplet.levels[1].basis) ")
        lines = PhotoEmission.determineLines(finalMultiplet, initialMultiplet, settings)
        # Display all selected lines before the computations start
        if  settings.printBefore    PhotoEmission.displayLines(lines)    end
        # Calculate all amplitudes and requested properties
        newLines = PhotoEmission.Line[]
        for  line in lines
            newLine = PhotoEmission.computeAmplitudesProperties(line, grid, settings) 
            push!( newLines, newLine)
        end
        # Print all results to screen
        PhotoEmission.displayRates(stdout, newLines)
        if  settings.calcAnisotropy    PhotoEmission.displayAnisotropies(stdout, newLines)    end
        PhotoEmission.displayLifetimes(stdout, newLines)
        #
        printSummary, iostream = Defaults.getDefaults("summary flag/stream")
        if  printSummary   PhotoEmission.displayRates(iostream, newLines)       
                           PhotoEmission.displayAnisotropies(stdout, newLines)
                           PhotoEmission.displayLifetimes(iostream, newLines)
        end
        #
        if    output    return( lines )
        else            return( nothing )
        end
    end


    """
    `PhotoEmission.computeLinesCascade(finalMultiplet::Multiplet, initialMultiplet::Multiplet, grid::Radial.Grid, 
                                       settings::PhotoEmission.Settings; output::Bool=true, printout::Bool=true)`  
        ... to compute the radiative transition amplitudes and all properties as requested by the given settings. The computations
            and printout is adapted for larger cascade computations by including only lines with at least one channel and by sending
            all printout to a summary file only. A list of lines::Array{PhotoEmission.Lines} is returned.
    """
    function  computeLinesCascade(finalMultiplet::Multiplet, initialMultiplet::Multiplet, grid::Radial.Grid, 
                                  settings::PhotoEmission.Settings; output=true, printout::Bool=true) 
        # Define a common subshell list for both multiplets
        subshellList = Basics.generate("subshells: ordered list for two bases", finalMultiplet.levels[1].basis, initialMultiplet.levels[1].basis)
        Defaults.setDefaults("relativistic subshell list", subshellList; printout=false)
        lines = PhotoEmission.determineLines(finalMultiplet, initialMultiplet, settings)
        # Display all selected lines before the computations start
        # if  settings.printBefore    PhotoEmission.displayLines(lines)    end
        # Calculate all amplitudes and requested properties
        newLines = PhotoEmission.Line[]
        for  (i,line)  in  enumerate(lines)
            if  rem(i,50) == 0    println("> Radiative line $i:")   end
            newLine = PhotoEmission.computeAmplitudesProperties(line, grid, settings, printout=printout) 
            #
            # Don't add this line if it does not contribute to the decay
            wa = 0.
            for  ch in newLine.channels   wa = wa + abs(ch.amplitude)^2    end
            if   wa == 0.    continue    end
            push!( newLines, newLine)
        end
        # Print all results to a summary file, if requested
        printSummary, iostream = Defaults.getDefaults("summary flag/stream")
        if  printSummary   PhotoEmission.displayRates(iostream, newLines)    end
        #
        if    output    return( newLines )
        else            return( nothing )
        end
    end



    """
    `PhotoEmission.computeAmplitudesProperties(line::PhotoEmission.Line, grid::Radial.Grid, settings::Einstein.Settings; printout::Bool=true)`  
        ... to compute all amplitudes and properties of the given line; a line::Einstein.Line is returned for which the amplitudes and 
            properties are now evaluated.
    """
    function  computeAmplitudesProperties(line::PhotoEmission.Line, grid::Radial.Grid, settings::PhotoEmission.Settings; printout::Bool=true)
        global JAC_counter
        newChannels = PhotoEmission.Channel[];    rateC = 0.;    rateB = 0.
        for channel in line.channels
            #
            amplitude = PhotoEmission.amplitude("emission", channel.multipole, channel.gauge, line.omega, 
                                                line.finalLevel, line.initialLevel, grid, printout=printout)
            #
            push!( newChannels, PhotoEmission.Channel( channel.multipole, channel.gauge, amplitude) )
            if       channel.gauge == Basics.Coulomb     rateC = rateC + abs(amplitude)^2
            elseif   channel.gauge == Basics.Babushkin   rateB = rateB + abs(amplitude)^2
            elseif   channel.gauge == Basics.Magnetic    rateB = rateB + abs(amplitude)^2;   rateC = rateC + abs(amplitude)^2
            end
        end
        #     
        # Calculate the photonrate and angular beta if requested 
        wa = 8.0pi * Defaults.getDefaults("alpha") * line.omega / (AngularMomentum.twoJ(line.initialLevel.J) + 1) * 
                                                      (AngularMomentum.twoJ(line.finalLevel.J) + 1)
        photonrate  = EmProperty(wa * rateC, wa * rateB)    
        angularBeta = EmProperty(-9., -9.)
        line = PhotoEmission.Line( line.initialLevel, line.finalLevel, line.omega, photonrate, angularBeta, true, newChannels)
        return( line )
    end


    """
    `PhotoEmission.determineChannels(finalLevel::Level, initialLevel::Level, settings::PhotoEmission.Settings)`  
        ... to determine a list of PhotoEmission.Channel for a transitions from the initial to final level and by taking into 
            account the particular settings of for this computation; an Array{PhotoEmission.Channel,1} is returned.
    """
    function determineChannels(finalLevel::Level, initialLevel::Level, settings::PhotoEmission.Settings)
        channels = PhotoEmission.Channel[];   
        symi = LevelSymmetry(initialLevel.J, initialLevel.parity);    symf = LevelSymmetry(finalLevel.J, finalLevel.parity) 
        for  mp in settings.multipoles
            if   AngularMomentum.isAllowedMultipole(symi, mp, symf)
                hasMagnetic = false
                for  gauge in settings.gauges
                    # Include further restrictions if appropriate
                    if     string(mp)[1] == 'E'  &&   gauge == Basics.UseCoulomb      push!(channels, PhotoEmission.Channel(mp, Basics.Coulomb,   0.) )
                    elseif string(mp)[1] == 'E'  &&   gauge == Basics.UseBabushkin    push!(channels, PhotoEmission.Channel(mp, Basics.Babushkin, 0.) )  
                    elseif string(mp)[1] == 'M'  &&   !(hasMagnetic)                  push!(channels, PhotoEmission.Channel(mp, Basics.Magnetic,  0.) );
                                                        hasMagnetic = true; 
                    end 
                end
            end
        end
        return( channels )  
    end


    """
    `PhotoEmission.determineLines(finalMultiplet::Multiplet, initialMultiplet::Multiplet, settings::PhotoEmission.Settings)`  
        ... to determine a list of PhotoEmission Line's for transitions between the levels from the given initial- and 
            final-state multiplets and by taking into account the particular selections and settings for this computation; 
            an Array{PhotoEmission.Line,1} is returned. Apart from the level specification, all physical properties are set 
            to zero during the initialization process.  
    """
    function  determineLines(finalMultiplet::Multiplet, initialMultiplet::Multiplet, settings::PhotoEmission.Settings)
        lines = PhotoEmission.Line[]
        for  iLevel  in  initialMultiplet.levels
            for  fLevel  in  finalMultiplet.levels
                if  Basics.selectLevelPair(iLevel, fLevel, settings.lineSelection)
                    omega = iLevel.energy - fLevel.energy   + settings.photonEnergyShift
                    if  omega <= settings.mimimumPhotonEnergy  ||  omega > settings.maximumPhotonEnergy    continue   end  

                    channels = PhotoEmission.determineChannels(fLevel, iLevel, settings) 
                    if   length(channels) == 0   continue   end
                    push!( lines, PhotoEmission.Line(iLevel, fLevel, omega, EmProperty(0., 0.), EmProperty(0., 0.), true, channels) )
                end
            end
        end
        return( lines )
    end


    """
    `PhotoEmission.displayAnisotropies(stream::IO, lines::Array{PhotoEmission.Line,1})`  
        ... to list all energies and anisotropy parameters of the selected lines. A neat table is printed but nothing is 
            returned otherwise.
    """
    function  displayAnisotropies(stream::IO, lines::Array{PhotoEmission.Line,1})
        nx = 153
        println(stream, " ")
        println(stream, "  Anisotropy (structure) functions:")
        println(stream, " ")
        println(stream, "  ", TableStrings.hLine(nx))
        sa = "  ";   sb = "  "
        sa = sa * TableStrings.center(18, "i-level-f"; na=2);                         sb = sb * TableStrings.hBlank(20)
        sa = sa * TableStrings.center(18, "i--J^P--f"; na=4);                         sb = sb * TableStrings.hBlank(22)
        sa = sa * TableStrings.center(14, "Energy"   ; na=4);               
        sb = sb * TableStrings.center(14,TableStrings.inUnits("energy"); na=4)
        sa = sa * TableStrings.flushleft(20, "Multipoles";   na=0);              
        sa = sa * TableStrings.center(14, "f_2 (Coulomb)";   na=3);       
        sa = sa * TableStrings.center(14, "f_2 (Babushkin)"; na=3);       
        sa = sa * TableStrings.center(14, "f_4 (Coulomb)";   na=3);       
        sa = sa * TableStrings.center(14, "f_4 (Babushkin)"; na=3);       
        println(stream, sa);    println(stream, sb);    println(stream, "  ", TableStrings.hLine(nx)) 
        #   
        for  line in lines
            f2Coulomb   = 0.0im;    f2Babushkin   = 0.0im;    f4Coulomb = 0.0im;    f4Babushkin = 0.0im;   mpList = EmMultipole[]
            normCoulomb = 0.;       normBabushkin = 0.
            sa  = "  ";    isym = LevelSymmetry( line.initialLevel.J, line.initialLevel.parity)
                           fsym = LevelSymmetry( line.finalLevel.J,   line.finalLevel.parity)
            sa = sa * TableStrings.center(18, TableStrings.levels_if(line.initialLevel.index, line.finalLevel.index); na=2)
            sa = sa * TableStrings.center(18, TableStrings.symmetries_if(isym, fsym); na=4)
            sa = sa * @sprintf("%.8e", Defaults.convertUnits("energy: from atomic", line.omega)) * "    "
            # Now compute the anisotropy parameter from the amplitudes
            for  ch in line.channels
                if  !(ch.multipole  in  mpList)    push!(mpList, ch.multipole)    end
                for  chp  in line.channels
                    #
                    if  ch.gauge  in  [ EmGauge("Coulomb"), EmGauge("Magnetic")]
                        if  ch == chp    normCoulomb = normCoulomb + (abs(ch.amplitude)^2)    end
                        angL  = AngularJ64(ch.multipole.L);   p  = Basics.multipole_p(ch.multipole)
                        angLp = AngularJ64(ch.multipole.L);   pp = Basics.multipole_p(chp.multipole)
                        angJi = line.initialLevel.J;    angJf = line.finalLevel.J
                        #
                        f2Coulomb = f2Coulomb + 1.0im^(chp.multipole.L + pp - ch.multipole.L - p + 16)                         *
                                                AngularMomentum.phaseFactor([angJf, +1, angJi, +1, AngularJ64(3)])         *
                                                sqrt( (2ch.multipole.L+1) * (2chp.multipole.L+1) )                             * 
                                    AngularMomentum.ClebschGordan(angL, AngularM64(1), angLp, AngularM64(-1), AngularJ64(2), AngularM64(0) ) *
                                                (1. + (-1.)^(ch.multipole.L + p + chp.multipole.L + pp - 2) )                  *
                                                AngularMomentum.Wigner_6j(angL, angLp, AngularJ64(2), angJi, angJi, angJf) *
                                                conj(ch.amplitude) * chp.amplitude
                        #
                        f4Coulomb = f4Coulomb + 1.0im^(chp.multipole.L + pp - ch.multipole.L - p + 16)                         *
                                                AngularMomentum.phaseFactor([angJf, +1, angJi, +1, AngularJ64(5)])         *
                                                sqrt( (2ch.multipole.L+1) * (2chp.multipole.L+1) )                             * 
                                    AngularMomentum.ClebschGordan(angL, AngularM64(1), angLp, AngularM64(-1), AngularJ64(4), AngularM64(0) ) *
                                                (1. + (-1.)^(ch.multipole.L + p + chp.multipole.L + pp - 2) )                  *
                                                AngularMomentum.Wigner_6j(angL, angLp, AngularJ64(4), angJi, angJi, angJf) *
                                                conj(ch.amplitude) * chp.amplitude
                    end
                    #
                    if  ch.gauge  in  [ EmGauge("Babushkin"), EmGauge("Magnetic")]
                        if  ch == chp    normBabushkin = normBabushkin + (abs(ch.amplitude)^2)    end
                        angL  = AngularJ64(ch.multipole.L);   p  = Basics.multipole_p(ch.multipole)
                        angLp = AngularJ64(ch.multipole.L);   pp = Basics.multipole_p(chp.multipole)
                        angJi = line.initialLevel.J;    angJf = line.finalLevel.J
                        #
                        f2Babushkin = f2Babushkin + 1.0im^(chp.multipole.L + pp - ch.multipole.L - p + 16)                         *
                                                    AngularMomentum.phaseFactor([angJf, +1, angJi, +1, AngularJ64(3)])         *
                                                    sqrt( (2ch.multipole.L+1) * (2chp.multipole.L+1) )                             * 
                                      AngularMomentum.ClebschGordan(angL, AngularM64(1), angLp, AngularM64(-1), AngularJ64(2), AngularM64(0) ) *
                                                    (1. + (-1.)^(ch.multipole.L + p + chp.multipole.L + pp - 2) )                  *
                                                    AngularMomentum.Wigner_6j(angL, angLp, AngularJ64(2), angJi, angJi, angJf) *
                                                    conj(ch.amplitude) * chp.amplitude
                        #
                        f4Babushkin = f4Babushkin + 1.0im^(chp.multipole.L + pp - ch.multipole.L - p + 16)                         *
                                                    AngularMomentum.phaseFactor([angJf, +1, angJi, +1, AngularJ64(5)])         *
                                                    sqrt( (2ch.multipole.L+1) * (2chp.multipole.L+1) )                             * 
                                      AngularMomentum.ClebschGordan(angL, AngularM64(1), angLp, AngularM64(-1), AngularJ64(4), AngularM64(0) ) *
                                                    (1. + (-1.)^(ch.multipole.L + p + chp.multipole.L + pp - 2) )                  *
                                                    AngularMomentum.Wigner_6j(angL, angLp, AngularJ64(4), angJi, angJi, angJf) *
                                                    conj(ch.amplitude) * chp.amplitude
                    end
                end
            end
            f2Coulomb   = f2Coulomb   / normCoulomb   * sqrt(AngularMomentum.twoJ(line.initialLevel.J) + 1) / 2.
            f4Coulomb   = f4Coulomb   / normCoulomb   * sqrt(AngularMomentum.twoJ(line.initialLevel.J) + 1) / 2.
            f2Babushkin = f2Babushkin / normBabushkin * sqrt(AngularMomentum.twoJ(line.initialLevel.J) + 1) / 2.
            f4Babushkin = f4Babushkin / normBabushkin * sqrt(AngularMomentum.twoJ(line.initialLevel.J) + 1) / 2.
            #
            sa = sa * TableStrings.flushleft( 17, TableStrings.multipoleList(mpList);  na=3)
            sa = sa * TableStrings.flushright(15, @sprintf("%.8e", f2Coulomb.re);    na=3) 
            sa = sa * TableStrings.flushright(15, @sprintf("%.8e", f2Babushkin.re);  na=3)
            sa = sa * TableStrings.flushright(15, @sprintf("%.8e", f4Coulomb.re);    na=3)
            sa = sa * TableStrings.flushright(15, @sprintf("%.8e", f4Babushkin.re);  na=3)
            println(stream, sa)
        end
        println(stream, "  ", TableStrings.hLine(nx))
        #
        return( nothing )
    end


    """
    `PhotoEmission.displayLifetimes(stream::IO, lines::Array{PhotoEmission.Line,1})`  
        ... to list all lifetimes as derived from the selected lines. A neat table is printed but nothing is returned otherwise.
    """
    function  displayLifetimes(stream::IO, lines::Array{PhotoEmission.Line,1})
        # Determine all initial levels (and their level information) for printing the lifetimes
        ilevels = Int64[];   istr = String[]
        for  i = 1:length(lines)
            ii = lines[i].initialLevel.index;   
            if  !(ii in ilevels)   
               sa  = "  ";    sym = LevelSymmetry( lines[i].initialLevel.J, lines[i].initialLevel.parity )
               sa = sa * TableStrings.center(10, TableStrings.level(lines[i].initialLevel.index); na=2)
               sa = sa * TableStrings.center(10, string(sym); na=4)
               sa = sa * @sprintf("%.6e", Defaults.convertUnits("energy: from atomic", lines[i].initialLevel.energy)) * "    "
               push!( ilevels, ii);    push!( istr, sa )   
            end
        end
        # Determine the lifetime (in a.u.) of the selected initial levels
        irates = Basics.EmProperty[]
        for  ii in  ilevels
            waCoulomb = 0.;    waBabushkin = 0.
            for  i = 1:length(lines)
                if   lines[i].initialLevel.index == ii    
                    waCoulomb   = waCoulomb   + lines[i].photonRate.Coulomb
                    waBabushkin = waBabushkin + lines[i].photonRate.Babushkin
                end
            end
            push!(irates, EmProperty( waCoulomb, waBabushkin) )
        end
        
        nx = 105
        println(stream, " ")
        println(stream, "  PhotoEmission lifetimes (as derived from these computations):")
        println(stream, " ")
        println(stream, "  ", TableStrings.hLine(nx))
        sa = "  ";   sb = "  "
        sa = sa * TableStrings.center(10, "Level"; na=2);                              sb = sb * TableStrings.hBlank(12)
        sa = sa * TableStrings.center(10, "J^P";   na=4);                              sb = sb * TableStrings.hBlank(14)
        sa = sa * TableStrings.center(12, "Level energy"   ; na=3);               
        sb = sb * TableStrings.center(12,TableStrings.inUnits("energy"); na=3)
        sa = sa * TableStrings.center(12, "Used Gauge"    ; na=6);                     sb = sb * TableStrings.hBlank(18)
        sa = sa * TableStrings.center(26, "Lifetime"; na=3);       
        sb = sb * TableStrings.center(26, "[a.u.]"*"          "*TableStrings.inUnits("time"); na=5)
        sa = sa * TableStrings.center(12, "Decay widths"; na=4);       
        sb = sb * TableStrings.center(12, TableStrings.inUnits("energy"); na=4)
        println(stream, sa);    println(stream, sb);    println(stream, "  ", TableStrings.hLine(nx)) 
        #    
        for  ii = 1:length(ilevels)
            sa = istr[ii]
            sa = sa * "Coulomb          " * @sprintf("%.6e",              1.0/irates[ii].Coulomb)     * "  "
            sa = sa * @sprintf("%.6e", Defaults.convertUnits("time: from atomic",   1.0/irates[ii].Coulomb) )   * "    "
            sa = sa * @sprintf("%.6e", Defaults.convertUnits("energy: from atomic",     irates[ii].Coulomb) )
            println(stream, sa)
            sa = repeat(" ", length(istr[ii]) )
            sa = sa * "Babushkin        " * @sprintf("%.6e",              1.0/irates[ii].Babushkin)   * "  "
            sa = sa * @sprintf("%.6e", Defaults.convertUnits("time: from atomic",   1.0/irates[ii].Babushkin) ) * "    "
            sa = sa * @sprintf("%.6e", Defaults.convertUnits("energy: from atomic",     irates[ii].Babushkin) )
            println(stream, sa)
        end
        println(stream, "  ", TableStrings.hLine(nx))
        #
        return( nothing )
    end


    """
    `PhotoEmission.displayLines(lines::Array{PhotoEmission.Line,1})`  
        ... to display a list of lines and channels that have been selected due to the prior settings. A neat table of all 
            selected transitions and energies is printed but nothing is returned otherwise.
    """
    function  displayLines(lines::Array{PhotoEmission.Line,1})
        nx = 95
        println(" ")
        println("  Selected radiative lines:")
        println(" ")
        println("  ", TableStrings.hLine(nx))
        sa = "  ";   sb = "  "
        sa = sa * TableStrings.center(18, "i-level-f"; na=2);                         sb = sb * TableStrings.hBlank(20)
        sa = sa * TableStrings.center(18, "i--J^P--f"; na=4);                         sb = sb * TableStrings.hBlank(22)
        sa = sa * TableStrings.center(14, "Energy"; na=4);              
        sb = sb * TableStrings.center(14, TableStrings.inUnits("energy"); na=4)
        sa = sa * TableStrings.flushleft(30, "List of multipoles"; na=4);             sb = sb * TableStrings.hBlank(34)
        println(sa);    println(sb);    println("  ", TableStrings.hLine(nx)) 
        #   
        for  line in lines
            sa  = "  ";    isym = LevelSymmetry( line.initialLevel.J, line.initialLevel.parity)
                           fsym = LevelSymmetry( line.finalLevel.J,   line.finalLevel.parity)
            sa = sa * TableStrings.center(18, TableStrings.levels_if(line.initialLevel.index, line.finalLevel.index); na=2)
            sa = sa * TableStrings.center(18, TableStrings.symmetries_if(isym, fsym); na=4)
            sa = sa * @sprintf("%.8e", Defaults.convertUnits("energy: from atomic", line.omega)) * "    "
            mpGaugeList = Tuple{EmMultipole,EmGauge}[]
            for  i in 1:length(line.channels)
                push!( mpGaugeList, (line.channels[i].multipole, line.channels[i].gauge) )
            end
            sa = sa * TableStrings.multipoleGaugeTupels(50, mpGaugeList)
            println( sa )
        end
        println("  ", TableStrings.hLine(nx))
        println(" ")
        #
        return( nothing )
    end


    """
    `PhotoEmission.displayRates(stream::IO, lines::Array{PhotoEmission.Line,1})`  
        ... to list all results, energies, rates, etc. of the selected lines. A neat table is printed but nothing is 
            returned otherwise.
    """
    function  displayRates(stream::IO, lines::Array{PhotoEmission.Line,1})
        nx = 145
        println(stream, " ")
        println(stream, "  Einstein coefficients, transition rates and oscillator strengths:")
        println(stream, " ")
        println(stream, "  ", TableStrings.hLine(nx))
        sa = "  ";   sb = "  "
        sa = sa * TableStrings.center(18, "i-level-f"; na=2);                         sb = sb * TableStrings.hBlank(20)
        sa = sa * TableStrings.center(18, "i--J^P--f"; na=4);                         sb = sb * TableStrings.hBlank(22)
        sa = sa * TableStrings.center(12, "Energy"   ; na=4);               
        sb = sb * TableStrings.center(12,TableStrings.inUnits("energy"); na=4)
        sa = sa * TableStrings.center( 9, "Multipole"; na=0);                         sb = sb * TableStrings.hBlank(10)
        sa = sa * TableStrings.center(11, "Gauge"    ; na=4);                         sb = sb * TableStrings.hBlank(17)
        sa = sa * TableStrings.center(26, "A--Einstein--B"; na=3);       
        sb = sb * TableStrings.center(26, TableStrings.inUnits("rate")*"          "*TableStrings.inUnits("rate"); na=2)
        sa = sa * TableStrings.center(11, "Osc. strength"    ; na=3);                 sb = sb * TableStrings.hBlank(17)
        sa = sa * TableStrings.center(12, "Decay widths"; na=4);       
        sb = sb * TableStrings.center(12, TableStrings.inUnits("energy"); na=4)
        println(stream, sa);    println(stream, sb);    println(stream, "  ", TableStrings.hLine(nx)) 
        #   
        for  line in lines
            for  ch in line.channels
                sa  = "  ";    isym = LevelSymmetry( line.initialLevel.J, line.initialLevel.parity)
                               fsym = LevelSymmetry( line.finalLevel.J,   line.finalLevel.parity)
                sa = sa * TableStrings.center(18, TableStrings.levels_if(line.initialLevel.index, line.finalLevel.index); na=2)
                sa = sa * TableStrings.center(18, TableStrings.symmetries_if(isym, fsym); na=4)
                sa = sa * @sprintf("%.6e", Defaults.convertUnits("energy: from atomic", line.omega)) * "    "
                sa = sa * TableStrings.center(9,  string(ch.multipole); na=4)
                sa = sa * TableStrings.flushleft(11, string(ch.gauge);  na=2)
                chRate =  8pi * Defaults.getDefaults("alpha") * line.omega / (AngularMomentum.twoJ(line.initialLevel.J) + 1) * (abs(ch.amplitude)^2) * 
                                                                 (AngularMomentum.twoJ(line.finalLevel.J) + 1)
                sa = sa * @sprintf("%.6e", Basics.recast("rate: radiative, to Einstein A",  line, chRate)) * "  "
                sa = sa * @sprintf("%.6e", Basics.recast("rate: radiative, to Einstein B",  line, chRate)) * "    "
                sa = sa * @sprintf("%.6e", Basics.recast("rate: radiative, to g_f",         line, chRate)) * "    "
                sa = sa * @sprintf("%.6e", Basics.recast("rate: radiative, to decay width", line, chRate)) * "      "
                ##x sa = sa * @sprintf("%.5e  %.5e", ch.amplitude.re, ch.amplitude.im) * "        "
                println(stream, sa)
            end
        end
        println(stream, "  ", TableStrings.hLine(nx))
        #
        return( nothing )
    end

end # module

