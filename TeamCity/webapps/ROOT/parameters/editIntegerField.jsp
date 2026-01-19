<%@include file="/include-internal.jsp"%>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props"  %>
<jsp:useBean id="context" scope="request" type="jetbrains.buildServer.controllers.parameters.ParameterEditContext"/>

<tr>
  <th style="width: 20%"><label for="minValue">Minimum value:</label></th>
  <td>
    <props:textProperty name="minValue" className="longField"/>
    <span class="smallNote">Specify minimum value if needed</span>
    <span id="error_minValue" class="error"></span>
  </td>
</tr>

<tr>
  <th><label for="maxValue">Maximum value:</label></th>
  <td>
    <props:textProperty name="maxValue" className="longField"/>
    <span class="smallNote">Specify maximum value if needed</span>
    <span id="error_maxValue" class="error"></span>
  </td>
</tr>
