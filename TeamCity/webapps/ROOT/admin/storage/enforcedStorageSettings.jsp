<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="enforcedStorage" scope="request" type="jetbrains.buildServer.serverSide.artifacts.ArtifactStorageType"/>

<div id="ArtifactStorages" class="section noMargin">
<h2 class="noBorder">Artifacts storage</h2>
<bs:smallNote>
  On this page you can define how TeamCity stores and accesses artifacts produced by builds of this project and its subprojects.
</bs:smallNote>

Storage <b><c:out value="${enforcedStorage.name}"/></b> was enforced to be used in this project and all child projects and can't be changed.

