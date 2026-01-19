<%@include file="/include-internal.jsp"%>
<%@ page import="jetbrains.buildServer.serverSide.storage.ArtifactsStorageSettingsController" %>
<bs:linkScript>
  /js/bs/editStorage.js
</bs:linkScript>
<jsp:include page="<%=ArtifactsStorageSettingsController.PATH%>"/>