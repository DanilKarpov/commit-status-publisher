<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<jsp:useBean id="_object" scope="request" type="jetbrains.buildServer.serverSide.NodeResponsibility"/>
<bs:out value="\"${_object.displayName}\""/>