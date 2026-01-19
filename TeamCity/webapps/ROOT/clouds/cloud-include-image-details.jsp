<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@include file="/include-internal.jsp" %>
<jsp:useBean id="image" type="jetbrains.buildServer.clouds.CloudImage" scope="request"/>

<bs:changeRequest key="image" value="${image}">
  <ext:extensionsAvailable placeId="<%=PlaceId.CLOUD_IMAGE_DETAILS%>">
    <tr class="image_details">
      <td colspan="2">
        <ext:includeExtensions placeId="<%=PlaceId.CLOUD_IMAGE_DETAILS%>"/>
      </td>
    </tr>
  </ext:extensionsAvailable>
</bs:changeRequest>
