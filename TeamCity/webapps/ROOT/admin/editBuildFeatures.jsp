<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<c:set var="cameFrom" value='<%=WebUtil.encode(request.getAttribute("pageUrl") + "&init=1")%>'/>
<admin:editBuildTypePage selectedStep="buildFeatures">
  <jsp:attribute name="body_include">
    <%@ include file="editBuildFeaturesResources.jspf" %>

    <div class="section noMargin">
      <h2 class="noBorder">Build Features</h2>
      <bs:smallNote>
        In this section you can configure build features. A build feature is a piece of functionality that can affect a build process or reporting its results.<bs:help file="Adding+Build+Features"/>
      </bs:smallNote>

      <jsp:include page="/admin/editBuildFeaturesList.html?id=${buildForm.settingsId}&featurePlace=GENERAL"/>
    </div>
  </jsp:attribute>
</admin:editBuildTypePage>
