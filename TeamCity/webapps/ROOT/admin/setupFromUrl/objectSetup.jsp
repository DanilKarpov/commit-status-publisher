<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@include file="/include-internal.jsp"%>
<jsp:useBean id="objectSetupBean" type="jetbrains.buildServer.controllers.admin.projects.setupFromUrl.SetupObjectFromResourceBean" scope="request"/>
<c:set var="parentProject" value="${objectSetupBean.parentProject}"/>
<c:set var="title" value="${objectSetupBean.objectType == 'PROJECT' ? 'Create Project From URL' : 'Create Build Configuration From URL'}"/>
<bs:page disableScrollingRestore="true">
  <jsp:attribute name="page_title">${title}</jsp:attribute>
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/admin/adminMain.css
    </bs:linkCSS>
    <bs:linkScript>
      /js/bs/editProject.js
    </bs:linkScript>
    <script type="text/javascript">
      <bs:trimWhitespace>
        <admin:projectPathJS startProject="${parentProject}" startAdministration="${true}"/>

        BS.Navigation.items.push({
          title: "${title}",
          url: '<c:url value="/admin/createObjectFromUrl.html?parentId=${parentProject.externalId}&objectType=${objectSetupBean.objectType}"/>',
          selected: true
        });
      </bs:trimWhitespace>
    </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <div id="container" class="clearfix" style="width:70%;">
      <ext:includeExtensions placeId="<%=PlaceId.ADMIN_SETUP_OBJECT_FROM_RESOURCE%>"/>
    </div>
  </jsp:attribute>
</bs:page>
