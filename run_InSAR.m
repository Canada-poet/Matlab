v =-20:2:20;
v_Est_Vy_ = zeros(length(v),length(v));
v_Est_Vx_ = v_Est_Vy_;
a_Est_Ax_ = v_Est_Vy_;
v_Est_Err_Vy_ = v_Est_Vy_;
v_Est_Err_Vx_ = v_Est_Vy_;
a_Est_Err_Ax_ = v_Est_Vy_;
%{
v_Est_Vy_wvd = zeros(length(v),length(v));
v_Est_Vy_crr = v_Est_Vy_wvd;
v_Est_Vy_gaf = v_Est_Vy_wvd;
v_Est_Err_Vy_wvd = zeros(length(v),length(v));
v_Est_Err_Vy_crr = v_Est_Vy_wvd;
v_Est_Err_Vy_gaf = v_Est_Vy_wvd;
%}

for vx = 1 : length(v)
	parfor vy = 1 : length(v)
		%[v_Est_Vy_wvd(vx,vy), v_Est_Vy_crr(vx,vy), v_Est_Vy_gaf(vx,vy)]= DualRx(v(vx),v(vy),0,0);
		[v_Est_Vx_(vx,vy), v_Est_Vy_(vx,vy), a_Est_Ax_(vx,vy)]= DualRx(0,v(vy),v(vx)/2,0);
	end
	fprintf('.')
	if mod(vx,10) == 0
		fprintf('\n')
	end
end

v_Est_Err_Vx_ = v_Est_Vx_ - zeros(length(v),length(v));
v_Est_Err_Vy_ = v_Est_Vy_ - ones(length(v),1) * v;
a_Est_Err_Ax_ = a_Est_Ax_ - v.* ones(1,length(v));

%%
figure
imagesc(v,v,v_Est_Err_Vx_)
	xlabel('$v_y$', 'Interpreter', 'latex')
	ylabel('$v_x$', 'Interpreter', 'latex')
	set(gca,'Ydir','normal'),colorbar, colormap('Jet')
	%caxis([-2 3])
	plot_para('Maximize',true,'Filename','errmap_vx')
figure
imagesc(v,v,v_Est_Err_Vy_)
	xlabel('$v_y$', 'Interpreter', 'latex')
	ylabel('$v_x$', 'Interpreter', 'latex')
	set(gca,'Ydir','normal'),colorbar, colormap('Jet')
	%caxis([-1 1])
	plot_para('Maximize',true,'Filename','errmap_vy')
figure
imagesc(v,v,a_Est_Err_Ax_)
	xlabel('$v_y$', 'Interpreter', 'latex')
	ylabel('$v_x$', 'Interpreter', 'latex')
	set(gca,'Ydir','normal'),colorbar, colormap('Jet')
	%caxis([-1 1])
	plot_para('Maximize',true,'Filename','errmap_ax')
	
	
%{
figure
imagesc(v,v,v_Est_Err_Vy_)
	xlabel('$v_y$', 'Interpreter', 'latex')
	ylabel('$v_x$', 'Interpreter', 'latex')
	set(gca,'Ydir','normal'),colorbar, colormap('Jet')
	caxis([-1 1])
	plot_para('Maximize',true,'Filename','errmap')
%}