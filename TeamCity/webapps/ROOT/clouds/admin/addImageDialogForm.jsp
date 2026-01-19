<%@include file="/include-internal.jsp" %>

<jsp:useBean id="availableImages" scope="request" type="java.util.Collection<jetbrains.buildServer.clouds.CloudImageParameters>"/>

<script type="text/javascript">

</script>

<table  class="runnerFormTable">
  <tr>
    <th><label for="image">Cloud image:<l:star/></label></th>
    <td>
      <forms:select name="image" enableFilter="${true}" onchange="BS.Clouds.Admin.Images.EditDialog.selectImage();">
        <forms:option value="">-- Please choose cloud image --</forms:option>
        <c:forEach var="image" items="${availableImages}">
          <forms:option value="${image.internalId}" data="${image.projectId}"><c:out value="${image.id}"/></forms:option>
        </c:forEach>
      </forms:select>
    </td>
  </tr>
</table>

<input type="hidden" id="sourceImageInternalId" name="sourceImageInternalId"/>
<input type="hidden" id="sourceImageProjectId" name="sourceImageProjectId"/>