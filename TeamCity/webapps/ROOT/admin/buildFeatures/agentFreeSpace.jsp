<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<jsp:useBean id="bean" class="jetbrains.buildServer.buildFeatures.freeSpace.FreeSpaceConstants"/>

<tr>
  <td colspan="2">
    <em>The build agent will try to ensure the specified amount of disk space is free before starting the build. Checkout directories of older builds can be deleted to free space.</em><bs:help file="Free+Disk+Space"/>
  </td>
</tr>
<tr class="noBorder">
  <th><label for="${bean.freeSpaceKey}">Required free space:</label></th>
  <td>
    <props:textProperty name="${bean.freeSpaceKey}" className="longField" style="width: 99%;"/>
    <span class="smallNote">Enter number of bytes or use one of <it>kb, mb, gb or tb</it> suffixes to specify size.</span>
    <span class="error" id="error_${bean.freeSpaceKey}"/>
  </td>
</tr>
<tr class="noBorder">
  <th><label for="${bean.failBuildKey}">Fail build if sufficient disk space cannot be freed:</label></th>
  <td>
    <props:checkboxProperty name="${bean.failBuildKey}"/>
  </td>
</tr>
