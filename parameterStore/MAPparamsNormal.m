function method=MAPparamsNormal ...
    (BFlist, sampleRate, showParams, paramChanges)
% MAPparams<> establishes a complete set of MAP parameters
% Parameter file names must be of the form <MAPparams> <name>
%
% input arguments
%  BFlist     (optional) specifies the desired list of channel BFs
%    otherwise defaults set below
%  sampleRate (optional), default is 50000.
%  showParams (optional) =1 prints out the complete set of parameters
% output argument
%  method passes a miscelleny of values

global inputStimulusParams OMEParams DRNLParams IHC_cilia_RPParams
global IHC_VResp_VivoParams IHCpreSynapseParams  AN_IHCsynapseParams
global MacGregorParams MacGregorMultiParams  filteredSACFParams
global experiment % used by calls from multiThreshold only


currentFile=mfilename;                      % i.e. the name of this mfile
method.parameterSource=currentFile(10:end); % for the record

efferentDelay=0.010;
method.segmentDuration=efferentDelay;

if nargin<3, showParams=0; end
if nargin<2, sampleRate=50000; end
if nargin<1 || BFlist(1)<0 % if BFlist= -1, set BFlist to default
    lowestBF=250; 	highestBF= 8000; 	numChannels=21;
    % 21 chs (250-8k)includes BFs at 250 500 1000 2000 4000 8000
    BFlist=round(logspace(log10(lowestBF),log10(highestBF),numChannels));
end
% BFlist=1000;

% preserve for backward campatibility
method.nonlinCF=BFlist; 
method.dt=1/sampleRate; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set  model parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%  #1 inputStimulus
inputStimulusParams=[];
inputStimulusParams.sampleRate= sampleRate; 

%%  #2 outerMiddleEar
OMEParams=[];  % clear the structure first
% outer ear resonances band pass filter  [gain lp order  hp]
OMEParams.externalResonanceFilters=      [ 10 1 1000 4000];
                                       
% highpass stapes filter  
%  Huber gives 2e-9 m at 80 dB and 1 kHz (2e-13 at 0 dB SPL)
OMEParams.OMEstapesLPcutoff= 1000;
OMEParams.stapesScalar=	     45e-9;

% Acoustic reflex: maximum attenuation should be around 25 dB Price (1966)
% i.e. a minimum ratio of 0.056.
% 'spikes' model: AR based on brainstem spiking activity (LSR)
OMEParams.rateToAttenuationFactor=0.006;   % * N(all ICspikes)
% OMEParams.rateToAttenuationFactor=0;   % * N(all ICspikes)

% 'probability model': Ar based on AN firing probabilities (LSR)
OMEParams.rateToAttenuationFactorProb=0.01;% * N(all ANrates)
% OMEParams.rateToAttenuationFactorProb=0;% * N(all ANrates)

% asymptote should be around 100-200 ms
OMEParams.ARtau=.05; % AR smoothing function
% delay must be longer than the segment length
OMEParams.ARdelay=efferentDelay;  %Moss gives 8.5 ms latency
OMEParams.ARrateThreshold=0;

%%  #3 DRNL
DRNLParams=[];  % clear the structure first
DRNLParams.BFlist=BFlist;

% DRNL nonlinear path
DRNLParams.a=5e4;     % DRNL.a=0 means no OHCs (no nonlinear path)
DRNLParams.a=2e4;     % DRNL.a=0 means no OHCs (no nonlinear path)

DRNLParams.b=8e-6;    % *compression threshold raised compression
% DRNLParams.b=1;    % b=1 means no compression

DRNLParams.c=0.2;     % compression exponent
% nonlinear filters
DRNLParams.nonlinCFs=BFlist;
DRNLParams.nonlinOrder=	3;           % order of nonlinear gammatone filters
p=0.2895;   q=170;  % human  (% p=0.14;   q=366;  % cat)
DRNLParams.nlBWs=  p * BFlist + q;
DRNLParams.p=p;   DRNLParams.q=q;   % save p and q for printing only

% DRNL linear path:
DRNLParams.g=100;     % linear path gain factor
% linCF is not necessarily the same as nonlinCF
minLinCF=153.13; coeffLinCF=0.7341;   % linCF>nonlinBF for BF < 1 kHz
DRNLParams.linCFs=minLinCF+coeffLinCF*BFlist;
DRNLParams.linOrder=	3;           % order of linear gammatone filters
minLinBW=100; coeffLinBW=0.6531;
DRNLParams.linBWs=minLinBW + coeffLinBW*BFlist; % bandwidths of linear  filters

% DRNL MOC efferents
DRNLParams.MOCdelay = efferentDelay;            % must be < segment length!

% 'spikes' model: MOC based on brainstem spiking activity (HSR)
DRNLParams.rateToAttenuationFactor = .01;  % strength of MOC
%      DRNLParams.rateToAttenuationFactor = 0;  % strength of MOC
% 'probability' model: MOC based on AN spiking activity (HSR)
DRNLParams.rateToAttenuationFactorProb = .0055;  % strength of MOC
% DRNLParams.rateToAttenuationFactorProb = .0;  % strength of MOC
DRNLParams.MOCrateThresholdProb =70;                % spikes/s probability only

DRNLParams.MOCtau =.1;                         % smoothing for MOC


%% #4 IHC_cilia_RPParams

IHC_cilia_RPParams.tc=	0.0003;   % 0.0003 filter time simulates viscocity
% IHC_cilia_RPParams.tc=	0.0005;   % 0.0003 filter time simulates viscocity
IHC_cilia_RPParams.C=	0.03;      % 0.1 scalar (C_cilia ) 
IHC_cilia_RPParams.u0=	5e-9;       
IHC_cilia_RPParams.s0=	30e-9;
IHC_cilia_RPParams.u1=	1e-9;
IHC_cilia_RPParams.s1=	1e-9;

IHC_cilia_RPParams.Gmax= 6e-9;    % 2.5e-9 maximum conductance (Siemens)
IHC_cilia_RPParams.Ga=	1e-9;  % 4.3e-9 fixed apical membrane conductance
IHC_cilia_RPParams.Ga=	.8e-9;  % 4.3e-9 fixed apical membrane conductance

%  #5 IHC_RP
IHC_cilia_RPParams.Cab=	4e-012;         % IHC capacitance (F)
% IHC_cilia_RPParams.Cab=	1e-012;         % IHC capacitance (F)
IHC_cilia_RPParams.Et=	0.100;          % endocochlear potential (V)

IHC_cilia_RPParams.Gk=	2e-008;         % 1e-8 potassium conductance (S)
IHC_cilia_RPParams.Ek=	-0.08;          % -0.084 K equilibrium potential
IHC_cilia_RPParams.Rpc=	0.04;           % combined resistances


%%  #5 IHCpreSynapse
IHCpreSynapseParams=[];
IHCpreSynapseParams.GmaxCa=	14e-9;% maximum calcium conductance
IHCpreSynapseParams.GmaxCa=	12e-9;% maximum calcium conductance
IHCpreSynapseParams.ECa=	0.066;  % calcium equilibrium potential
IHCpreSynapseParams.beta=	400;	% determine Ca channel opening
IHCpreSynapseParams.gamma=	100;	% determine Ca channel opening
IHCpreSynapseParams.tauM=	0.00005;	% membrane time constant ?0.1ms
IHCpreSynapseParams.power=	3;
% reminder: changing z has a strong effect on HF thresholds (like Et)
IHCpreSynapseParams.z=	    2e42;   % scalar Ca -> vesicle release rate

LSRtauCa=35e-6;            HSRtauCa=85e-6;            % seconds
% LSRtauCa=35e-6;            HSRtauCa=70e-6;            % seconds
IHCpreSynapseParams.tauCa= [LSRtauCa HSRtauCa]; %LSR and HSR fiber

%%  #6 AN_IHCsynapse
% c=kym/(y(l+r)+kl)	(spontaneous rate)
% c=(approx)  ym/l  (saturated rate)
AN_IHCsynapseParams=[];             % clear the structure first
AN_IHCsynapseParams.M=	12;         % maximum vesicles at synapse
AN_IHCsynapseParams.y=	4;          % depleted vesicle replacement rate
AN_IHCsynapseParams.y=	6;          % depleted vesicle replacement rate

AN_IHCsynapseParams.x=	30;         % replenishment from re-uptake store
AN_IHCsynapseParams.x=	60;         % replenishment from re-uptake store

% reduce l to increase saturated rate
AN_IHCsynapseParams.l=	100; % *loss rate of vesicles from the cleft
AN_IHCsynapseParams.l=	250; % *loss rate of vesicles from the cleft

AN_IHCsynapseParams.r=	500; % *reuptake rate from cleft into cell
% AN_IHCsynapseParams.r=	300; % *reuptake rate from cleft into cell

AN_IHCsynapseParams.refractory_period=	0.00075;
% number of AN fibers at each BF (used only for spike generation)
AN_IHCsynapseParams.numFibers=	100; 
AN_IHCsynapseParams.TWdelay=0.004;  % ?delay before stimulus first spike

AN_IHCsynapseParams.ANspeedUpFactor=5; % longer epochs for computing spikes.

%%  #7 MacGregorMulti (first order brainstem neurons)
MacGregorMultiParams=[];
MacGregorMultiType='chopper'; % MacGregorMultiType='primary-like'; %choose
switch MacGregorMultiType
    case 'primary-like'
        MacGregorMultiParams.nNeuronsPerBF=	10;   % N neurons per BF
        MacGregorMultiParams.type = 'primary-like cell';
        MacGregorMultiParams.fibersPerNeuron=4;   % N input fibers
        MacGregorMultiParams.dendriteLPfreq=200;  % dendritic filter
        MacGregorMultiParams.currentPerSpike=0.11e-6; % (A) per spike
        MacGregorMultiParams.Cap=4.55e-9;   % cell capacitance (Siemens)
        MacGregorMultiParams.tauM=5e-4;     % membrane time constant (s)
        MacGregorMultiParams.Ek=-0.01;      % K+ eq. potential (V)
        MacGregorMultiParams.dGkSpike=3.64e-5; % K+ cond.shift on spike,S
        MacGregorMultiParams.tauGk=	0.0012; % K+ conductance tau (s)
        MacGregorMultiParams.Th0=	0.01;   % equilibrium threshold (V)
        MacGregorMultiParams.c=	0.01;       % threshold shift on spike, (V)
        MacGregorMultiParams.tauTh=	0.015;  % variable threshold tau
        MacGregorMultiParams.Er=-0.06;      % resting potential (V)
        MacGregorMultiParams.Eb=0.06;       % spike height (V)

    case 'chopper'
        MacGregorMultiParams.nNeuronsPerBF=	10;   % N neurons per BF
        MacGregorMultiParams.type = 'chopper cell';
        MacGregorMultiParams.fibersPerNeuron=10;  % N input fibers
%         MacGregorMultiParams.fibersPerNeuron=6;  % N input fibers

        MacGregorMultiParams.dendriteLPfreq=50;   % dendritic filter
        MacGregorMultiParams.currentPerSpike=35e-9; % *per spike
%         MacGregorMultiParams.currentPerSpike=30e-9; % *per spike
        
        MacGregorMultiParams.Cap=1.67e-8; % ??cell capacitance (Siemens)
        MacGregorMultiParams.tauM=0.002;  % membrane time constant (s)
        MacGregorMultiParams.Ek=-0.01;    % K+ eq. potential (V)
        MacGregorMultiParams.dGkSpike=1.33e-4; % K+ cond.shift on spike,S
        MacGregorMultiParams.tauGk=	0.0005;% K+ conductance tau (s)
        MacGregorMultiParams.Th0=	0.01; % equilibrium threshold (V)
        MacGregorMultiParams.c=	0;        % threshold shift on spike, (V)
        MacGregorMultiParams.tauTh=	0.02; % variable threshold tau
        MacGregorMultiParams.Er=-0.06;    % resting potential (V)
        MacGregorMultiParams.Eb=0.06;     % spike height (V)
        MacGregorMultiParams.PSTHbinWidth=	1e-4;
end

%%  #8 MacGregor (second-order neuron). Only one per channel
MacGregorParams=[];                 % clear the structure first
MacGregorParams.type = 'chopper cell';
MacGregorParams.fibersPerNeuron=10; % N input fibers
MacGregorParams.dendriteLPfreq=100; % dendritic filter
MacGregorParams.currentPerSpike=120e-9;% *(A) per spike
MacGregorParams.currentPerSpike=40e-9;% *(A) per spike

MacGregorParams.Cap=16.7e-9;        % cell capacitance (Siemens)
MacGregorParams.tauM=0.002;         % membrane time constant (s)
MacGregorParams.Ek=-0.01;           % K+ eq. potential (V)
MacGregorParams.dGkSpike=1.33e-4;   % K+ cond.shift on spike,S
MacGregorParams.tauGk=	0.0005;     % K+ conductance tau (s)
MacGregorParams.Th0=	0.01;       % equilibrium threshold (V)
MacGregorParams.c=	0;              % threshold shift on spike, (V)
MacGregorParams.tauTh=	0.02;       % variable threshold tau
MacGregorParams.Er=-0.06;           % resting potential (V)
MacGregorParams.Eb=0.06;            % spike height (V)
MacGregorParams.debugging=0;        % (special)
% wideband accepts input from all channels (of same fiber type)
% use wideband to create inhibitory units
MacGregorParams.wideband=0;         % special for wideband units
% MacGregorParams.saveAllData=0;

%%  #9 filteredSACF
minPitch=	300; maxPitch=	3000; numPitches=60;    % specify lags
pitches=100*log10(logspace(minPitch/100, maxPitch/100, numPitches));
filteredSACFParams.lags=1./pitches;     % autocorrelation lags vector
filteredSACFParams.acfTau=	.003;       % time constant of running ACF
filteredSACFParams.lambda=	0.12;       % slower filter to smooth ACF
filteredSACFParams.plotFilteredSACF=1;  % 0 plots unfiltered ACFs
filteredSACFParams.plotACFs=0;          % special plot (see code)
%  filteredSACFParams.usePressnitzer=0; % attenuates ACF at  long lags
filteredSACFParams.lagsProcedure=  'useAllLags';
% filteredSACFParams.lagsProcedure=  'useBernsteinLagWeights';
% filteredSACFParams.lagsProcedure=  'omitShortLags';
filteredSACFParams.criterionForOmittingLags=3;

% checks
if AN_IHCsynapseParams.numFibers<MacGregorMultiParams.fibersPerNeuron
    error('MacGregorMulti: too few input fibers for input to MacG unit')
end


%% now accept last minute parameter changes required by the calling program
% paramChanges
if nargin>3 && ~isempty(paramChanges)
    nChanges=length(paramChanges);
    for idx=1:nChanges
        eval(paramChanges{idx})
    end
end


%% write all parameters to the command window
% showParams is currently set at the top of htis function
if showParams
    fprintf('\n %%%%%%%%\n')
    fprintf('\n%s\n', method.parameterSource)
    fprintf('\n')
    nm=UTIL_paramsList(whos);
    for i=1:length(nm)
        %         eval(['UTIL_showStruct(' nm{i} ', ''' nm{i} ''')'])
        if ~strcmp(nm(i), 'method')
            eval(['UTIL_showStructureSummary(' nm{i} ', ''' nm{i} ''', 10)'])
        end
    end

    % highlight parameter changes made locally
    if nargin>3 && ~isempty(paramChanges)
        fprintf('\n Local parameter changes:\n')
        for i=1:length(paramChanges)
            disp(paramChanges{i})
        end
    end
end

% for backward compatibility
experiment.comparisonData=[];
