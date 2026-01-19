<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>

<admin:editBuildTypePage selectedStep="runType">
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/admin/buildRunners.css
    </bs:linkCSS>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <c:url value='/admin/editRunType.html?init=1&id=${buildForm.settingsId}&runnerId=${buildForm.buildRunnerBean.id}&runTypeInfoKey=' var="addStepUrl"/>

    <h2 class="noBorder">Auto-detected Build Steps</h2>
    <bs:smallNote>
      Build steps and their settings are detected automatically by scanning VCS repository.
      You can <a href="${addStepUrl}">configure build steps manually</a> if auto-detect did not find relevant build steps.<bs:help file="Configuring+Build+Steps"/>
    </bs:smallNote>

    <div id="discoveredRunners"></div>

    <div id="discoveryProgressContainer">
      <forms:saving id="discoveryProgress" className="progressRingInline"/> Scanning VCS repositories, please wait...
      <forms:button className="btn_mini" onclick="BS.RunnersDiscovery.cancel('${buildForm.settingsId}')" id="discoveryCancelButton">Cancel</forms:button>
    </div>

    <script type="text/javascript">
      BS.RunnersDiscovery.update('${buildForm.settingsId}');
    </script>

  </jsp:attribute>
</admin:editBuildTypePage>
