LE = [zeros(1,6);0,0.05,0.15,0.25,0.3,0.5;zeros(1,6)];
TE = LE;
TE(1,:) = TE(1,:)+0.1;
Flare = 30;
Fold = -45;
Twist = 0;
ContrlDeflection = -25;

wings = FWT_Model.gen_FWT45(Flare,0,Twist,false);
wings(2) = FWT_Model.gen_MainWing(Flare,false);
wings(3) = FWT_Model.gen_MainWing(Flare,true);
wings(4) = FWT_Model.gen_FWT45(Flare,0,Twist,true);
model = laca.model.Aircraft(wings);
model.Name = 'AlphaBeta';
sections = [model.Wings.WingSections];
sections(strcmp(string({sections.ControlName}),"ail_r")).ControlDeflection = ContrlDeflection;
sections(strcmp(string({sections.ControlName}),"ail_l")).ControlDeflection = ContrlDeflection;


f = figure(1);clf;
model.draw
f.CurrentAxes.ZDir = 'Reverse';
ax = gca;
ax.Clipping = 'off';
axis equal

%% gen vlm model
AoA = 10;
Beta = 25;
V_func = fh.roty(-AoA)*fh.rotz(-Beta)*[-20 0 0]';

vlm_model = laca.vlm.Model.From_laca_model(model,0.02,5,false);

% define left FWT
cs = laca.vlm.ControlSurface('Right_FWT',1);
panels = vlm_model.Wings(1).Panels;
cs.HingeNodes = [panels(3,find(vlm_model.Wings(1).isTE,1,'last')),...
    panels(2,find(vlm_model.Wings(1).isLE,1,'last'))];
cs.Nodes = 1:vlm_model.Wings(1).NNodes;
vlm_model.Wings(1).ControlSurfaces = cs;

% define right FWT
cs = laca.vlm.ControlSurface('Right_FWT',1);
panels = vlm_model.Wings(end).Panels;
cs.HingeNodes = [panels(1,find(vlm_model.Wings(end).isLE,1,'first')),...
    panels(4,find(vlm_model.Wings(end).isTE,1,'first'))];
cs.Nodes = 1:vlm_model.Wings(end).NNodes;
vlm_model.Wings(end).ControlSurfaces = cs;

% deflect wingtips
vlm_model.Wings(1).ControlSurfaces.Deflection =  Fold;
vlm_model.Wings(end).ControlSurfaces.Deflection =  Fold;

f = figure(2);clf;
vlm_model.draw
f.CurrentAxes.ZDir = 'Reverse';
ax = gca;
ax.Clipping = 'off';
axis equal

%% gen rings
V_dir = V_func./vecnorm(V_func);
vlm_model = vlm_model.generate_rings(V_dir * 0.5);
f = figure(3);clf;
vlm_model.draw_rings
f.CurrentAxes.ZDir = 'Reverse';
ax = gca;
ax.Clipping = 'off';
axis equal


%% solve
vlm_model = vlm_model.generate_AIC();
vlm_model = vlm_model.solve(V_func,1.225);

f = figure(4);clf;
vlm_model.draw('param','P')
% for y = -0.55:0.275:0.55
%     for z = -0.1:0.1:0.1
%         vlm_model.draw_streamline([0.2,y,z]')
%     end
% end


f.CurrentAxes.ZDir = 'Reverse';
ax = gca;
ax.Clipping = 'off';
axis equal

